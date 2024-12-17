/*
*  parameters
*/

param location string
param webAppName string
param reserved bool = true
@allowed(
  [
    'app,linux' //Webapp Linux
    'api' //API APP
    'app' //Windows App
    'function,app' //FunctionApp Windows
    'functionapp,linux' //functionApp Linux
    'app,linux,container' //functionApp Linux
  ]
)
param kind string = 'app,linux'
param vnetRG string
param vnetName string
param subnetname string
param subnetPepName string

@description('Type of managed service identity.')
@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned, UserAssigned'
  'UserAssigned'
])
param identityType string = 'SystemAssigned'

@description('The Runtime stack of current web app')
param userAssignedIdentities object = {}

@description('The Runtime stack of current web app')
@allowed([
  'DOTNETCORE:7.0'
  'DOTNETCORE:6.0'
  'NODE:18-lts'
  'NODE:16-lts'
  'NODE:14-lts'
  'PYTHON:3.11'
  'PYTHON:3.10'
  'PYTHON:3.9'
  'PYTHON:3.8'
  'PYTHON:3.7'
  'PHP:8.2'
  'PHP:8.1'
  'PHP:8.0'
  'RUBY:2.7'
  'JAVA:17-java17'
  'JAVA:11-java11'
  'JAVA:8-jre8'
  'JBOSSEAP:7-java11'
  'JBOSSEAP:7-java8'
  'TOMCAT:10.0-java17'
  'TOMCAT:10.0-java11'
  'TOMCAT:10.0-jre8'
  'TOMCAT:9.0-java17'
  'TOMCAT:9.0-java11'
  'TOMCAT:9.0-jre8'
  'TOMCAT:8.5-java11'
  'TOMCAT:8.5-jre8'
  'GO:1.19'
  'DOCKER' // Add 'DOCKER' as a generic option
])
param runtimeStack string
@description('Docker image for custom runtime. Required if runtimeStack is DOCKER.')
param dockerImage string = '' // Optional default, can enforce mandatory validation elsewhere.

param linuxFxVersion string
@description('.NET Framework version.')
param netFrameworkVersion string = ''
@description('Version of Node.js.')
param nodeVersion string = ''
@description('Version of PHP.')
param phpVersion string = ''
@description('Version of PowerShell.')
param powerShellVersion string = ''
@description('Java version.')
param javaVersion string = ''
@description('Python version.')
param pythonVersion string = ''
param functionsWorkerRuntime string = ''
@description('Site redundancy mode')
@allowed([
  'ActiveActive'
  'Failover'
  'GeoRedundant'
  'Manual'
  'None'
])
param redundancyMode string = 'None'
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
@description('Optional. Set the minimum TLS version on request to storage.')
param minimumTlsVersion string = '1.2'
@description('Optional. The name of the diagnostic setting, if deployed. If left empty, it defaults to "<resourceName>-diagnosticSettings".')
param diagnosticSettingsName string = ''
@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 30

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''


param diagnosticLogCategoriesToEnable array = [
  'allLogs'
]
@description('private Endpoint Group Id')
param privateEPGroupId string = 'sites'
@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param privateEndpoints array = []
@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set and networkAcls are not set.')
@allowed([
  ''
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'
@description('Optional. Networks ACLs, this value contains IPs to whitelist and/or Subnet information. For security reasons, it is recommended to set the DefaultAction Deny.')
param networkAcls object = {}
param appInsightsName string
param appPlanName string

@description('Optional. FTP Disabled by Default')
param ftpState string = 'Disabled'
param ftpAuth bool = false
param ipSecurityRestrictions array = [
  {
    ipAddress: '0.0.0.0/0'
    action: 'Deny'
    priority: 1000
    name: 'Block All'
    description: 'Deny all access'
  }
  {
    ipAddress: 'Any'
    action: 'Deny'
    priority: 2154652812
    name: 'Deny All'
    description: 'Deny all access'
  }
]
@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

// Variables //
var diagnosticsLogsSpecified = [for category in filter(diagnosticLogCategoriesToEnable, item => item != 'allLogs'): {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: false
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsLogs = contains(diagnosticLogCategoriesToEnable, 'allLogs') ? [
  {
    categoryGroup: 'allLogs'
    enabled: true
    retentionPolicy: {
      enabled: true
      days: diagnosticLogsRetentionInDays
    }
  }
] : diagnosticsLogsSpecified

@description('Optional. The app settings key-value pairs except for AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING.')
param appSettingsKeyValuePairs object = {}
var webSiteName = toLower('${webAppName}-app')

var appInsightsValues = !empty(appinsights.id) ? {
APPINSIGHTS_INSTRUMENTATIONKEY: appinsights.properties.InstrumentationKey
APPLICATIONINSIGHTS_CONNECTION_STRING: appinsights.properties.ConnectionString
} : {}

var expandedAppSettings = union(appSettingsKeyValuePairs, appInsightsValues)

/*
*  existing
*/
resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
  scope: az.resourceGroup(vnetRG)
}

resource subnetApp 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetname
  parent: vnet
}

resource subnetPep 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing  = {
  name: subnetPepName
  parent: vnet
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appPlanName
}
// resources

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webSiteName
  tags: {}
  kind: kind
  identity: {
    type: identityType
    userAssignedIdentities: identityType == 'SystemAssigned' ? json('null') : userAssignedIdentities
  }
  location: location
  properties: {
    reserved: reserved
    serverFarmId: appServicePlan.id
    redundancyMode: redundancyMode
    siteConfig: {
      http20Enabled: true
      ftpsState: ftpState
      linuxFxVersion: runtimeStack == 'DOCKER' ? dockerImage : (linuxFxVersion == '' ? null : linuxFxVersion)
      netFrameworkVersion: !empty(netFrameworkVersion) && (functionsWorkerRuntime == 'dotnet' || functionsWorkerRuntime == 'dotnet-isolated') ? netFrameworkVersion : null
      nodeVersion: !empty(nodeVersion) && functionsWorkerRuntime == 'node' ? nodeVersion : null
      phpVersion: !empty(phpVersion) && functionsWorkerRuntime == 'php' ? phpVersion : null
      powerShellVersion: !empty(powerShellVersion) && functionsWorkerRuntime == 'powershell' ? powerShellVersion : null
      javaVersion: !empty(javaVersion) && functionsWorkerRuntime == 'java' ? javaVersion : null
      pythonVersion: !empty(pythonVersion) && functionsWorkerRuntime == 'python' ? pythonVersion : null
      minTlsVersion: minimumTlsVersion
      httpLoggingEnabled: true
      logsDirectorySizeLimit: 35 //Default size limit. Max is 100MB
      ipSecurityRestrictions: ipSecurityRestrictions
    }
    publicNetworkAccess: !empty(publicNetworkAccess) ? any(publicNetworkAccess) : (!empty(privateEndpoints) && empty(networkAcls) ? 'Disabled' : null)
    virtualNetworkSubnetId: subnetApp.id
    httpsOnly: true
  }
}

resource webAppConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'authsettingsV2'
  kind: kind
  parent: webApp
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return403'
    }
  }
}

resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  kind: kind
  parent: webApp
  properties: expandedAppSettings
}

resource ftpallow 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  name: 'ftp'
  kind:kind
  parent: webApp
  properties: {
    allow: ftpAuth
  }
}

resource scmallow 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  name: 'scm'
  kind: kind
  parent: webApp
  properties: {
    allow: ftpAuth
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if (!(empty(subnetPepName))) {
  name: '${webApp.name}-01-pep'
  location: location
  tags: {}
  properties: {
    subnet: {
      id: subnetPep.id
    }
    privateLinkServiceConnections: [
      {
        name:  '${webApp.name}-01-pep'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            privateEPGroupId
          ]
        }
      }
    ]
  }
}

resource app_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticWorkspaceId)) {
  name: !empty(diagnosticSettingsName) ? diagnosticSettingsName : '${webSiteName}-diagnosticSettings'
  properties: {
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    logs: diagnosticsLogs
  }
  scope: webApp
}

module appplanroleAssignments './.bicep/role-assignment.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-app-Rbac-${index}'
  params: {
    description: roleAssignment.?description ?? ''
    principalIds: roleAssignment.principalIds
    principalType: roleAssignment.?principalType ?? ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: roleAssignment.?condition ?? ''
    delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId ?? ''
    resourceId: webApp.id
  }
}]

output appServiceAppHostName string = webApp.properties.defaultHostName
