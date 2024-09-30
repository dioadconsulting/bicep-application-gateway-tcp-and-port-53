param location string = resourceGroup().location

// doesn't apply
// doesn't work
module ag53To443VNet 'module.integration-vnet.bicep' = {
  name: 'ag53To443'
  params: {
    name: 'ag53To443'
    location: location
    serviceFrontendPort: 53
    serviceBackendIPAddress: '8.8.8.8'
    serviceBackendPort: 443
  }
}
