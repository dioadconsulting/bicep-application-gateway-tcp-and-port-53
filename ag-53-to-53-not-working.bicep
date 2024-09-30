param location string = resourceGroup().location

// doesn't apply
// doesn't work
module ag53To53VNet 'module.integration-vnet.bicep' = {
  name: 'ag53To53'
  params: {
    name: 'ag53To53'
    location: location
    serviceFrontendPort: 53
    serviceBackendIPAddress: '8.8.8.8'
    serviceBackendPort: 53
  }
}
