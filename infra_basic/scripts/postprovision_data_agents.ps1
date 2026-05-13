$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
. (Join-Path $PSScriptRoot 'sync_azd_hook_env.ps1')
Sync-AzdHookEnv -ProjectRoot $repoRoot
Set-Location $repoRoot
if (-not $env:POSTPROVISION_NON_INTERACTIVE) {
  $env:POSTPROVISION_NON_INTERACTIVE = '1'
}
& (Join-Path $repoRoot 'infra/scripts/data_scripts/run_upload_data_scripts.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $repoRoot 'infra/scripts/agent_scripts/run_create_agents_scripts.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
