targetScope = 'subscription'


@description(' It picks up Resource Group\'s location by default.')
param location string = 'westeurope'


param env string 

//Variables
var inputEnv = {
  DEV : loadYamlContent('../parameters/DEV.yaml')
 //SIT: loadYamlContent('../parameters/SIT.yaml')
}

var input = inputEnv[env]

resource rgApp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: input.appRG
  location: location
}

module serverFarm 'br/cloudregistry:modules/app-plan:v1.0.2' = {
  scope: rgApp
  name: 'app-plandeployment'
  params: {
    appName: input.appPlanName
    location: location
    diagnosticWorkspaceId:input.monitoringWorkspaceId
    roleAssignments: input.appRoleAssignments
    skuSize: input.skuSize
    capacity: input.capacity
   // kind: 'app,linux'
    reserved: true
  }
}
