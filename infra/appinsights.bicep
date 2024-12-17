targetScope = 'subscription'


@description(' It picks up Resource Group\'s location by default.')
param location string = 'westeurope'

param env string 

var inputEnv = {
  DEV : loadYamlContent('../parameters/DEV.yaml')
  SIT: loadYamlContent('../parameters/SIT.yaml')
}

var input = inputEnv[env]

resource rgApp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: input.appRG
  location: location
}

module appinsights 'br/cloudregistry:modules/app-insights:v1.0.1' = {
  scope: rgApp
  name: 'appinsights-deployment'
  params: {
    insightsName: input.appInsightsName
    laWorkspaceResourceId:input.monitoringWorkspaceId
    location: location
    roleAssignments: input.insightsRoleAssignments
    diagnosticWorkspaceId: input.monitoringWorkspaceId
  }
}
