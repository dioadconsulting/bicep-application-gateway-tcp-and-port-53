param location string = resourceGroup().location

// applies OK
// applies OK
module ag443To443VNet 'module.integration-vnet.bicep' = {
  name: 'ag443To443'
  params: {
    name: 'ag443To443'
    location: location
    serviceFrontendPort: 443
    serviceBackendIPAddress: '8.8.8.8'
    serviceBackendPort: 443
  }
}
