@description('Location for all resources.')
param location string = resourceGroup().location
param name string

param serviceFrontendPort int
param serviceBackendPort int
param serviceBackendIPAddress string

var integrationVNetName = '${name}VNet'
var integrationVNetAddressPrefix = '10.0.0.0/16'

var applicationGatewaySubnetPrefix = '10.0.0.0/24'
var applicationGatewaySubnetName = '${name}ApplicationGatewaySubnet'
var privateLinkSubnetPrefix = '10.0.1.0/24'
var privateLinkSubnetName = '${name}PrivateLinkSubnet'

resource vnetWorkload 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: integrationVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        integrationVNetAddressPrefix
      ]
    }
  }
}

resource applicationGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnetWorkload
  name: applicationGatewaySubnetName
  properties: {
    addressPrefix: applicationGatewaySubnetPrefix
    // privateEndpointNetworkPolicies: 'Disabled'
    networkSecurityGroup: {
      id: applicationGatewaySecurityGroup.id
    }
  }
}

resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnetWorkload
  name: privateLinkSubnetName
  properties: {
    addressPrefix: privateLinkSubnetPrefix
    networkSecurityGroup: {
      id: privateLinkSecurityGroup.id
    }
  }
  dependsOn: [
    applicationGatewaySubnet
  ]
}

resource applicationGatewaySecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${name}ApplicationGatewaySecurityGroup-${location}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'ApplicationGatewaySecurityRule'
        properties: {
          description: 'Allow Application Gateway Traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '65200-65535'
          ]
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'ApplicationGatewayLoadBalancerSecurityRule'
        properties: {
          description: 'Allow Application Load Balancer Traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 125
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowDnsOutbound'
        properties: {
          description: 'Allow Workload Outbound DNS Traffic (resolver to private-link endpoint)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '53'
          ]
          sourceAddressPrefix: 'virtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowServiceInbound'
        properties: {
          description: 'Allow Service Inbound Traffic (resolver to private-link endpoint)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            string(serviceFrontendPort)
          ]
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 175
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource privateLinkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${name}PrivateLinkSecurityGroup-${location}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowServiceInbound'
        properties: {
          description: 'Allow Service Inbound Traffic (resolver to private-link endpoint)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            string(serviceFrontendPort)
          ]
          sourceAddressPrefix: 'virtualNetwork'
          destinationAddressPrefix: 'virtualNetwork'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource applicationGatewayPip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${applicationGatewayName}PublicIp'
  location: location
  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

var applicationGatewayName = '${name}ApplicationGateway'

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: applicationGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayPublicFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: applicationGatewayPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: serviceFrontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: serviceBackendIPAddress
            }
          ]
        }
      }
    ]
    backendSettingsCollection: [
      {
        name: 'appGatewayBackendSettings'
        properties: {
          port: serviceBackendPort
          protocol: 'Tcp'
        }
      }
    ]
    listeners: [
      {
        name: 'appGatewayListener'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/frontendIPConfigurations/appGatewayPublicFrontendIP'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/frontendPorts/appGatewayFrontendPort'
          }
          protocol: 'Tcp'
        }
      }
    ]
    routingRules: [
      {
        id: 'appGatewayRule'
        name: 'appGatewayRule'
        properties: {
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/backendAddressPools/appGatewayBackendPool'
          }
          backendSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/backendSettingsCollection/appGatewayBackendSettings'
          }
          listener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/listeners/appGatewayListener'
          }
          priority: 100
          ruleType: 'Basic'
        }
      }
    ]
  }
}
