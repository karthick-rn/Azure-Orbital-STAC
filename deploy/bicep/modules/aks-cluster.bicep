// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param location string = resourceGroup().location 
param clusterName string
param nodeCount int = 3
param vmSize string = 'Standard_D2s_v4'
param networkPlugin string = 'azure'
param networkMode string = 'transparent'
param logAnalyticsWorkspaceResourceID string = ''
param vnetSubnetID string = ''
param clientId string = ''
param kubernetesVersion string = '1.25.4'

resource aks 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' = {
  name: clusterName
  location: location
  tags: {
    environment: environmentName
    type: 'k8s'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    oidcIssuerProfile: {
      enabled: true
    }
    agentPoolProfiles: [
      {
        name: 'default'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
        nodeLabels: {
          App : 'default'
        }
        vnetSubnetID: (empty(vnetSubnetID) ? json('null') : vnetSubnetID)
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: empty(logAnalyticsWorkspaceResourceID)?false:true
        config: empty(logAnalyticsWorkspaceResourceID)?{}:{
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceResourceID
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        identity: {
          clientId: clientId
        }
      }
    }
    networkProfile: {
      networkPlugin: networkPlugin
      networkMode: networkMode
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}

output Id string = aks.id
output principalId string = aks.identity.principalId
output kubeletIdentityId string = aks.properties.identityProfile.kubeletidentity.objectId
