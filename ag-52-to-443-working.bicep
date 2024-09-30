param location string = resourceGroup().location

// applies OK
// works OK
module ag52To443VNet 'module.integration-vnet.bicep' = {
  name: 'ag52To443'
  params: {
    name: 'ag52To443'
    location: location
    serviceFrontendPort: 52
    serviceBackendIPAddress: '8.8.8.8'
    serviceBackendPort: 443
  }
}
