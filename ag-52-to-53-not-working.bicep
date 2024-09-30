param location string = resourceGroup().location

// applies ok
// doesn't work
module ag52To53VNet 'module.integration-vnet.bicep' = {
  name: 'ag52To53'
  params: {
    name: 'ag52To53'
    location: location
    serviceFrontendPort: 52
    serviceBackendIPAddress: '8.8.8.8'
    serviceBackendPort: 53
  }
}
