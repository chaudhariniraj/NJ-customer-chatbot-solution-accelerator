"""Token usage extraction and Application Insights tracking helpers.

Extracts LLM token usage from agent_framework run results and emits custom
events to Application Insights for monitoring per-agent, per-model, per-user
token consumption.

Custom events emitted (visible in App Insights `customEvents` table):
  - LLM_Token_Usage_Summary  (one per request, aggregated totals)
  - LLM_Agent_Token_Usage    (one per agent involved in a request)
  - LLM_Model_Token_Usage    (one per model deployment involved)

This is adapted for the BYOCC single-agent-with-tools chatbot from the
multi-agent orchestration reference implementation
(microsoft/Multi-Agent-Custom-Automation-Engine-Solution-Accelerator,
branch psl-token-usage).
"""
from __future__ import annotations

import logging
from typing import Any, Dict, Optional, Tuple

try:
    from .event_utils import track_event_if_configured
except ImportError:
    from app.utils.event_utils import track_event_if_configured

logger = logging.getLogger(__name__)


def _coerce_int(value: Any) -> int:
    """Best-effort int conversion; returns 0 on failure."""
    try:
        if value is None:
            return 0
        return int(value)
    except (TypeError, ValueError):
        return 0


# Token-count field aliases used by various model providers / SDK versions.
_INPUT_KEYS = (
    "input_token_count",
    "input_tokens",
    "prompt_tokens",
    "promptTokens",
)
_OUTPUT_KEYS = (
    "output_token_count",
    "output_tokens",
    "completion_tokens",
    "completionTokens",
)
_TOTAL_KEYS = (
    "total_token_count",
    "total_tokens",
    "totalTokens",
)


def _read_usage_obj(usage_obj: Any) -> Optional[Tuple[int, int, int]]:
    """Read input/output/total counts from a usage-bearing object or dict."""
    if usage_obj is None:
        return None

    # dict-like
    if isinstance(usage_obj, dict):
        getter = usage_obj.get
    else:
        def getter(key, default=None):
            return getattr(usage_obj, key, default)

    inp = 0
    out = 0
    tot = 0
    for k in _INPUT_KEYS:
        v = getter(k)
        if v:
            inp = _coerce_int(v)
            break
    for k in _OUTPUT_KEYS:
        v = getter(k)
        if v:
            out = _coerce_int(v)
            break
    for k in _TOTAL_KEYS:
        v = getter(k)
        if v:
            tot = _coerce_int(v)
            break
    if tot == 0 and (inp or out):
        tot = inp + out
    if inp == 0 and out == 0 and tot == 0:
        return None
    return inp, out, tot


def extract_usage_from_agent_result(result: Any) -> Optional[Tuple[int, int, int]]:
    """Extract (input_tokens, output_tokens, total_tokens) from an
    agent_framework AgentRunResponse (or similar).

    Tries the following locations in order:
      1. result.usage_details / result.usage
      2. result.raw_representation.usage (OpenAI-style)
      3. Aggregated message contents (.messages[*].contents[*].usage_details)

    Returns None if no usage information is found.
    """
    if result is None:
        return None

    # 1. direct attribute
    for attr in ("usage_details", "usage"):
        usage = getattr(result, attr, None)
        found = _read_usage_obj(usage)
        if found:
            return found

    # 2. raw_representation.usage (OpenAI ChatCompletion-style)
    raw = getattr(result, "raw_representation", None)
    if raw is not None:
        found = _read_usage_obj(getattr(raw, "usage", None))
        if found:
            return found

    # 3. aggregate over messages -> contents -> usage_details
    messages = getattr(result, "messages", None) or []
    total_inp = 0
    total_out = 0
    total_tot = 0
    for msg in messages:
        contents = getattr(msg, "contents", None) or []
        for content in contents:
            usage = getattr(content, "usage_details", None) or getattr(content, "usage", None)
            found = _read_usage_obj(usage)
            if found:
                total_inp += found[0]
                total_out += found[1]
                total_tot += found[2]
    if total_inp or total_out or total_tot:
        if total_tot == 0:
            total_tot = total_inp + total_out
        return total_inp, total_out, total_tot

    return None


def track_token_usage(
    *,
    agent_name: str,
    model_deployment_name: str,
    input_tokens: int,
    output_tokens: int,
    total_tokens: int,
    user_id: Optional[str] = None,
    session_id: Optional[str] = None,
    additional_agents: Optional[Dict[str, str]] = None,
) -> None:
    """Emit summary, per-agent and per-model token usage events.

    Args:
        agent_name: Primary agent that produced the response (e.g. chat agent).
        model_deployment_name: Deployment name of the underlying model.
        input_tokens / output_tokens / total_tokens: Counts for this request.
        user_id / session_id: Optional context, included on every event.
        additional_agents: Optional mapping {agent_name -> model_deployment_name}
            for sub-agents/tools that participated in the request. Per-agent
            events are emitted for each entry with the SAME token totals (the
            SDK aggregates tool-agent usage into the parent response, so we
            attribute totals to each contributing agent for dashboard slicing).
    """
    if total_tokens <= 0 and input_tokens <= 0 and output_tokens <= 0:
        return

    props_common = {
        "user_id": user_id or "",
        "session_id": session_id or "",
    }

    # Summary
    try:
        agents = {agent_name: model_deployment_name}
        if additional_agents:
            agents.update({k: v for k, v in additional_agents.items() if k})
        models = {m for m in agents.values() if m}
        track_event_if_configured(
            "LLM_Token_Usage_Summary",
            {
                **props_common,
                "total_input_tokens": str(input_tokens),
                "total_output_tokens": str(output_tokens),
                "total_tokens": str(total_tokens),
                "agent_count": str(len(agents)),
                "model_count": str(len(models)),
            },
        )

        # Per-agent (primary first, then additional).
        # role/is_primary lets KQL filter:
        #   - role == "orchestrator" → use for true totals (avoids double-count)
        #   - role == "tool"         → use for invocation counts / which sub-agents ran
        for ag_name, ag_model in agents.items():
            is_primary = ag_name == agent_name
            role = "orchestrator" if is_primary else "tool"
            track_event_if_configured(
                "LLM_Agent_Token_Usage",
                {
                    **props_common,
                    "agent_name": ag_name,
                    "model_deployment_name": ag_model or "",
                    "input_tokens": str(input_tokens),
                    "output_tokens": str(output_tokens),
                    "total_tokens": str(total_tokens),
                    "is_primary": "true" if is_primary else "false",
                    "role": role,
                    "primary_agent_name": agent_name,
                },
            )

        # Per-model (one event per distinct model)
        for model in models:
            track_event_if_configured(
                "LLM_Model_Token_Usage",
                {
                    **props_common,
                    "model_deployment_name": model,
                    "input_tokens": str(input_tokens),
                    "output_tokens": str(output_tokens),
                    "total_tokens": str(total_tokens),
                },
            )

        logger.info(
            "[TOKEN USAGE] agent=%s model=%s input=%d output=%d total=%d user=%s session=%s",
            agent_name, model_deployment_name,
            input_tokens, output_tokens, total_tokens,
            user_id or "-", session_id or "-",
        )
    except Exception as exc:  # never let telemetry break the request
        logger.warning("track_token_usage failed: %s", exc)


def extract_and_track_usage(
    result: Any,
    *,
    agent_name: str,
    model_deployment_name: str,
    user_id: Optional[str] = None,
    session_id: Optional[str] = None,
    additional_agents: Optional[Dict[str, str]] = None,
) -> Optional[Tuple[int, int, int]]:
    """Convenience wrapper: extract usage from result and emit events.

    Returns the (input, output, total) tuple if found, else None.
    Safe to call when telemetry is not configured — extraction still occurs
    so callers may persist the result.
    """
    usage = extract_usage_from_agent_result(result)
    if not usage:
        logger.debug(
            "No token usage found on agent result for agent=%s", agent_name
        )
        return None
    inp, out, tot = usage
    track_token_usage(
        agent_name=agent_name,
        model_deployment_name=model_deployment_name,
        input_tokens=inp,
        output_tokens=out,
        total_tokens=tot,
        user_id=user_id,
        session_id=session_id,
        additional_agents=additional_agents,
    )
    return usage
