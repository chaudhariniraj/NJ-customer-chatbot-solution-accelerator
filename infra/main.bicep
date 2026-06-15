targetScope = 'resourceGroup'

@allowed([
  'bicep'
  'avm'
  'avm-waf'
])
@description('Deployment flavor router: bicep, avm, or avm-waf')
param deploymentFlavor string = 'bicep'

@description('Optional. A unique application/solution name for all resources in this deployment. This should be 3-16 characters long.')
@minLength(3)
@maxLength(16)
param solutionName string = 'ccsa'

@maxLength(5)
@description('Optional. A unique text suffix appended to resource names for uniqueness.')
param solutionUniqueText string = substring(uniqueString(subscription().id, resourceGroup().name, solutionName), 0, 5)

@metadata({
  azd: { type: 'location' }
})
@allowed([
  'australiaeast'
  'centralus'
  'eastasia'
  'eastus2'
  'japaneast'
  'northeurope'
  'southeastasia'
  'uksouth'
])
@description('Required. Primary Azure region for resource deployment.')
param location string

@description('Optional. Tags to apply to all resources.')
param tags object = {}

@allowed([
  'eastus2'
  'francecentral'
  'swedencentral'
])
@metadata({
  azd: {
    type: 'location'
    usageName: [
      'OpenAI.GlobalStandard.gpt4.1-mini,50'
      'OpenAI.GlobalStandard.text-embedding-3-small,10'
      'OpenAI.GlobalStandard.gpt-realtime-mini,1'
    ]
  }
})
@description('Required. Location for AI Foundry and model deployments.')
param azureAiServiceLocation string

@allowed([
  'Standard'
  'GlobalStandard'
])
@description('Optional. GPT model deployment type.')
param deploymentType string = 'GlobalStandard'

@description('Optional. Name of the GPT model to deploy.')
param gptModelName string = 'gpt-4.1-mini'

@description('Optional. Version of the GPT model to deploy.')
param gptModelVersion string = '2025-04-14'

@minValue(10)
@description('Optional. Capacity of the GPT deployment (TPM in thousands).')
param gptDeploymentCapacity int = 50

@allowed([
  'text-embedding-3-small'
])
@description('Optional. Name of the embedding model to deploy.')
param embeddingModel string = 'text-embedding-3-small'

@minValue(10)
@description('Optional. Capacity of the embedding model deployment.')
param embeddingDeploymentCapacity int = 10

@allowed([
  'gpt-realtime-mini'
])
@description('Optional. Name of the realtime model to deploy.')
param gptRealtimeModelName string = 'gpt-realtime-mini'

@description('Optional. Version of the realtime model to deploy.')
param gptRealtimeModelVersion string = '2025-10-06'

@minValue(1)
@description('Optional. Capacity of the realtime model deployment.')
param gptRealtimeDeploymentCapacity int = 1

@description('Optional. Azure OpenAI API version.')
param azureOpenaiAPIVersion string = '2025-01-01-preview'

@description('Optional. Azure AI Agent API version.')
param azureAiAgentApiVersion string = '2025-05-01'

@description('Optional. Docker image tag for app deployments.')
param imageTag string = 'latest_v2'

@description('Optional. Container registry endpoint used for app images.')
param containerRegistryEndpoint string = 'ccbcontainerreg.azurecr.io'

@allowed(['F1', 'D1', 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1', 'P2', 'P3', 'P1v3', 'P1v4'])
@description('Optional. App Service Plan SKU.')
param appServicePlanSku string = 'B2'

@description('Optional. Enable monitoring (App Insights + Log Analytics).')
param enableMonitoring bool = false

@description('Optional. Resource ID of an existing Log Analytics workspace. Empty creates a new one when monitoring is enabled.')
param existingLogAnalyticsWorkspaceId string = ''

@description('Optional. Resource ID of an existing AI Foundry project. Empty creates a new one.')
param existingFoundryProjectResourceId string = ''

@allowed(['User', 'ServicePrincipal'])
@description('Optional. Principal type of the deploying user. Use ServicePrincipal for CI/CD pipelines with OIDC.')
param deployingUserPrincipalType string = 'User'

module bicepDeployment './bicep/main.bicep' = {
  name: 'module-bicep-${solutionName}'
  params: {
    solutionName: solutionName
    solutionUniqueText: solutionUniqueText
    location: location
    tags: tags
    azureAiServiceLocation: azureAiServiceLocation
    deploymentType: deploymentType
    gptModelName: gptModelName
    gptModelVersion: gptModelVersion
    gptDeploymentCapacity: gptDeploymentCapacity
    embeddingModel: embeddingModel
    embeddingDeploymentCapacity: embeddingDeploymentCapacity
    gptRealtimeModelName: gptRealtimeModelName
    gptRealtimeModelVersion: gptRealtimeModelVersion
    gptRealtimeDeploymentCapacity: gptRealtimeDeploymentCapacity
    azureOpenaiAPIVersion: azureOpenaiAPIVersion
    azureAiAgentApiVersion: azureAiAgentApiVersion
    imageTag: imageTag
    containerRegistryEndpoint: containerRegistryEndpoint
    appServicePlanSku: appServicePlanSku
    enableMonitoring: enableMonitoring
    existingLogAnalyticsWorkspaceId: existingLogAnalyticsWorkspaceId
    existingFoundryProjectResourceId: existingFoundryProjectResourceId
    deployingUserPrincipalType: deployingUserPrincipalType
  }
}

output SOLUTION_NAME string = bicepDeployment.outputs.SOLUTION_NAME
output RESOURCE_GROUP_NAME string = bicepDeployment.outputs.RESOURCE_GROUP_NAME
output RESOURCE_GROUP_LOCATION string = bicepDeployment.outputs.RESOURCE_GROUP_LOCATION
output ACR_NAME string = bicepDeployment.outputs.ACR_NAME
output AI_SERVICE_NAME string = bicepDeployment.outputs.AI_SERVICE_NAME
output AI_FOUNDRY_RESOURCE_ID string = bicepDeployment.outputs.AI_FOUNDRY_RESOURCE_ID
output AI_SEARCH_SERVICE_RESOURCE_ID string = bicepDeployment.outputs.AI_SEARCH_SERVICE_RESOURCE_ID
output API_APP_NAME string = bicepDeployment.outputs.API_APP_NAME
output API_APP_URL string = bicepDeployment.outputs.API_APP_URL
output API_PID string = bicepDeployment.outputs.API_PID
output APP_ENV string = bicepDeployment.outputs.APP_ENV
output APPINSIGHTS_INSTRUMENTATIONKEY string = bicepDeployment.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output APPLICATIONINSIGHTS_CONNECTION_STRING string = bicepDeployment.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output AZURE_AI_AGENT_API_VERSION string = bicepDeployment.outputs.AZURE_AI_AGENT_API_VERSION
output AZURE_AI_AGENT_ENDPOINT string = bicepDeployment.outputs.AZURE_AI_AGENT_ENDPOINT
output AZURE_AI_AGENT_MODEL_DEPLOYMENT_NAME string = bicepDeployment.outputs.AZURE_AI_AGENT_MODEL_DEPLOYMENT_NAME
output AZURE_AI_PROJECT_CONN_STRING string = bicepDeployment.outputs.AZURE_AI_PROJECT_CONN_STRING
output AZURE_AI_PROJECT_NAME string = bicepDeployment.outputs.AZURE_AI_PROJECT_NAME
output AZURE_AI_SEARCH_ENDPOINT string = bicepDeployment.outputs.AZURE_AI_SEARCH_ENDPOINT
output AZURE_COSMOSDB_ACCOUNT string = bicepDeployment.outputs.AZURE_COSMOSDB_ACCOUNT
output AZURE_COSMOSDB_CONVERSATIONS_CONTAINER string = bicepDeployment.outputs.AZURE_COSMOSDB_CONVERSATIONS_CONTAINER
output AZURE_COSMOSDB_DATABASE string = bicepDeployment.outputs.AZURE_COSMOSDB_DATABASE
output AZURE_ENV_IMAGETAG string = bicepDeployment.outputs.AZURE_ENV_IMAGETAG
output AZURE_FOUNDRY_ENDPOINT string = bicepDeployment.outputs.AZURE_FOUNDRY_ENDPOINT
output AZURE_OPENAI_API_VERSION string = bicepDeployment.outputs.AZURE_OPENAI_API_VERSION
output AZURE_OPENAI_DEPLOYMENT_MODEL string = bicepDeployment.outputs.AZURE_OPENAI_DEPLOYMENT_MODEL
output AZURE_OPENAI_EMBEDDING_MODEL string = bicepDeployment.outputs.AZURE_OPENAI_EMBEDDING_MODEL
output AZURE_OPENAI_EMBEDDING_MODEL_CAPACITY int = bicepDeployment.outputs.AZURE_OPENAI_EMBEDDING_MODEL_CAPACITY
output AZURE_OPENAI_ENDPOINT string = bicepDeployment.outputs.AZURE_OPENAI_ENDPOINT
output AZURE_OPENAI_MODEL_DEPLOYMENT_TYPE string = bicepDeployment.outputs.AZURE_OPENAI_MODEL_DEPLOYMENT_TYPE
output AZURE_OPENAI_RESOURCE string = bicepDeployment.outputs.AZURE_OPENAI_RESOURCE
output COSMOS_DB_DATABASE_NAME string = bicepDeployment.outputs.COSMOS_DB_DATABASE_NAME
output COSMOS_DB_ENDPOINT string = bicepDeployment.outputs.COSMOS_DB_ENDPOINT
output DISPLAY_CHART_DEFAULT string = bicepDeployment.outputs.DISPLAY_CHART_DEFAULT
output FOUNDRY_CHAT_AGENT string = bicepDeployment.outputs.FOUNDRY_CHAT_AGENT
output FOUNDRY_POLICY_AGENT string = bicepDeployment.outputs.FOUNDRY_POLICY_AGENT
output FOUNDRY_PRODUCT_AGENT string = bicepDeployment.outputs.FOUNDRY_PRODUCT_AGENT
output AGENT_ID_CHAT string = bicepDeployment.outputs.AGENT_ID_CHAT
output REACT_APP_LAYOUT_CONFIG string = bicepDeployment.outputs.REACT_APP_LAYOUT_CONFIG
output USE_AI_PROJECT_CLIENT string = bicepDeployment.outputs.USE_AI_PROJECT_CLIENT
output USE_CHAT_HISTORY_ENABLED string = bicepDeployment.outputs.USE_CHAT_HISTORY_ENABLED
output WEB_APP_URL string = bicepDeployment.outputs.WEB_APP_URL
