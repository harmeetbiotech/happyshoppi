@description('Specifies the location of the resource for which UMI is created.')
param location string
param azAADUserAssignedIdentityName string

resource azureResourceUMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: azAADUserAssignedIdentityName
  location: location
}
