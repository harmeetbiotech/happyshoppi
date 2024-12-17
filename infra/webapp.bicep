targetScope = 'subscription'


@description(' It picks up Resource Group\'s location by default.')
param location string = 'westeurope'


param env string 

//Variables
var inputEnv = {
  DEV : loadYamlContent('../parameters/DEV.yaml')
  SIT: loadYamlContent('../parameters/SIT.yaml')
}

var input = inputEnv[env]

resource rgApp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: input.webAppRg
  location: location
}

// existing resources
 resource appPlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: input.webAppPlan
  scope:rgApp
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: input.webAppInsights
  scope: rgApp
}




module webapp1 './webapptemplate.bicep'  = {
  scope: rgApp
  name: 'webapp1-deployment'
  
  params: {
    //linuxFxVersion: input.webAppLinuxFXversion
    location: location
    subnetname: input.WebAppSubnet
    subnetPepName: input.WebPepSubnet
    vnetName: input.WebVnet
    vnetRG: input.WebVnetRg
    webAppName: input.webName
    appInsightsName: appInsights.name
    appPlanName: appPlan.name
    roleAssignments: input.webRoleAssignments
    kind: 'app,linux,container'
    runtimeStack: input.runtimeStack
    dockerImage: input.dockerImage
  }
}
