targetScope = 'resourceGroup'

@description('It picks up Resource Group\'s location by default.')
param location string = 'westeurope'

param env string 

// Variables
var inputEnv = {
  DEV: loadYamlContent('../parameters/DEV.yaml')
  //SIT: loadYamlContent('../parameters/SIT.yaml')
}

var input = inputEnv[env]

// Diagnostic Workspace Resource
resource diagnosticWorkspace 'Microsoft.OperationalInsights/workspaces@2023-01-01' = {
  name: '${input.appPlanName}-diag-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018' // Pricing tier for the workspace
    }
  }
}

// App Service Plan Resource
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: input.appPlanName
  location: location
  tags: {
    Environment: env
  }
  sku: {
    name: input.skuSize // Example: 'P1v2', 'S1', etc.
    capacity: input.capacity // The number of instances
  }
  properties: {
    reserved: true // Specifies if the plan is for Linux apps
  }
}

// Link Diagnostic Settings to App Service Plan
resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnosticSetting-${input.appPlanName}'
  scope: appServicePlan
  properties: {
    workspaceId: diagnosticWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
