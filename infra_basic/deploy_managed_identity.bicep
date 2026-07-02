// ========== Managed Identity ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Name')
param miName string 

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-05-31-preview' = {
  name: miName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

resource managedIdentityBackendApp 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-05-31-preview' = {
  name: '${solutionName}-backend-app-mi'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

output managedIdentityOutput object = {
  id: managedIdentity.id
  objectId: managedIdentity.properties.principalId
  clientId: managedIdentity.properties.clientId
  name: miName
}

output managedIdentityBackendAppOutput object = {
  id: managedIdentityBackendApp.id
  objectId: managedIdentityBackendApp.properties.principalId
  clientId: managedIdentityBackendApp.properties.clientId
  name: managedIdentityBackendApp.name
}
