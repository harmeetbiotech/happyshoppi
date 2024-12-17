targetScope = 'subscription'

@description('Specifies the environment of the managed identity.')
param env string

@description('Specifies the location of the managed identity.')
param location string = 'westeurope'

//-------------------------------------------------------------
// variables Section
//-------------------------------------------------------------

var inputEnv = {
  DEV : loadYamlContent('../parameters/DEV.yaml')
  // PRE : loadYamlContent('../parameters/PRE.yaml')
  // PRD: loadYamlContent('../parameters/PRD.yaml')
}

var input = inputEnv[env]

var locationShort = {
  westeurope: {
    short: 'weu'
  }
  northeurope: {
    short: 'neu'
  }
}

var serviceCode = 'col'

var envPrefix = '${serviceCode}-${locationShort[location].short}-${toLower(env)}'

var umiObjects  = toObject(input.userManagedIdentities, entry => entry.name, entry => entry.properties)

/* creates a user managed identity for a requested service*/
// module sqlAksPodUserIdentity './resources/userManagedIdentity.bicep' = [for item in items(umiObjects): {
  module sqlAksPodUserIdentity 'br/cloudregistry:modules/umi:v1.0.0' = [for item in items(umiObjects): {
  name: '${envPrefix}-${item.key}-umi'
  scope: az.resourceGroup(item.value.targetResourceGroupName)
  params: {
    azAADUserAssignedIdentityName: item.value.azAADUserAssignedIdentityName
    location: location
  }
}]
