# Azure Application Gateway, TCP and port 53


## Description

This repository outlines various scenarios to try and prove that port `53` doesn't work properly with application gateway's in TCP mode. Even though the documentation (https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-components#ports) says it should work. For ref documentation says that the only ports not supported for Application Gateway V2 is port `22`.

Each of the bicep files shares a common application gateway module. This is to try and make obvious the minor changes in configuration are only the frontend and backend ports.

Each of the bicep files that doesn't start with `module.` can be applied directly to an Azure subscription.

The subscription will need to have the `AllowApplicationGatewayTlsProxy` preview feature enabled.

Each bicep file that has a suffix of `not-working` doesn't work for some reason, be that creating the Azure Application Gateway doesn't complete, or it does complete, but doesn't work.

The various scenarios and their results are outlined in the following table:



| Bicep File | Frontend Port | Backend Port | Result | Comments |
|------------|---------------|--------------|--------|----------|
| `ag-443-to-443-working.bicep`         |    443           |       443       |    (/)    |     Works as expected     |
| `ag-52-to-443-working.bicep`         |    52           |       443       |    (/)    |     Works as expected     |
| `ag-52-to-53-not-working.bicep`         |    52           |       53       |    (x)    |     Applies OK, Doesn't work     |
| `ag-53-to-53-not-working.bicep`         |    53           |       53       |    (x)    |     Doesn't apply. Doesn't work     |
| `ag-53-to-443-not-working.bicep`         |    53           |       53       |    (x)    |     Doesn't apply. Doesn't work     |


In summary, there are two things that don't appear to work correctly:
1. using port `53` as a frontend port stops the Azure Application Gateway from creating correctly (it times out with an `Internal Server Error` message, with no further information).
1. when using port `53` as a backend port, while the application gateway is created ok, traffic isn't routed properly and connections time out.

Using ports `52` and `54` in place of `53` also works.


# Test Results
## ag-443-to-443-working.bicep
### Bicep Apply
```shell
az group create --name ag-443-to-443 --location "UK South"
az deployment group create \
  --name ag-443-to-443-$(date +%s) \
  --resource-group ag-443-to-443 \
  --template-file ag-443-to-443-working.bicep
  {
  "id": "/subscriptions/GUID/resourceGroups/ag-443-to-443/providers/Microsoft.Resources/deployments/ag-443-to-443-1727692349",
  "location": null,
  "name": "ag-443-to-443-1727692349",
  "properties": {
    ...
    "provisioningState": "Succeeded",
    "templateHash": "11635741927726003995",
    "templateLink": null,
    "timestamp": "2024-09-30T10:36:51.167871+00:00",
    "validatedResources": null
  },
  "resourceGroup": "ag-443-to-443",
  "tags": null,
  "type": "Microsoft.Resources/deployments"
}
```
### Connectivity Test
```shell
$ curl --insecure  https://172.167.190.21:443
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>302 Moved</TITLE></HEAD><BODY>
<H1>302 Moved</H1>
The document has moved
<A HREF="https://dns.google/">here</A>.
</BODY></HTML>
```
## ag-52-to-443-working.bicep
### Bicep Apply
```shell
az group create --name ag-52-to-443 --location "UK South"
az deployment group create \
  --name ag-52-to-443-$(date +%s) \
  --resource-group ag-52-to-443 \
  --template-file ag-52-to-443-working.bicep
  {
  "id": "/subscriptions/GUID/resourceGroups/ag-52-to-443/providers/Microsoft.Resources/deployments/ag-52-to-443-1727692774",
  "location": null,
  "name": "ag-52-to-443-1727692774",
  "properties": {
    ...
    "provisioningState": "Succeeded",
    "templateHash": "526520915450688801",
    "templateLink": null,
    "timestamp": "2024-09-30T10:44:05.517004+00:00",
    "validatedResources": null
  },
  "resourceGroup": "ag-52-to-443",
  "tags": null,
  "type": "Microsoft.Resources/deployments"
}
```
### Connectivity Test
```shell
$ curl --insecure https://51.143.191.145:52
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>302 Moved</TITLE></HEAD><BODY>
<H1>302 Moved</H1>
The document has moved
<A HREF="https://dns.google/">here</A>.
</BODY></HTML>
```
## ag-52-to-53-not-working.bicep
This example applies ok and create an Application Gateway, but it doesn't work.
### Bicep Apply
```shell
az group create --name ag-52-to-53 --location "UK South"
az deployment group create \
  --name ag-52-to-53-$(date +%s) \
  --resource-group ag-52-to-53 \
  --template-file ag-52-to-53-not-working.bicep
  {
  "id": "/subscriptions/GUID/resourceGroups/ag-52-to-443/providers/Microsoft.Resources/deployments/ag-52-to-53-1727693226",
  "location": null,
  "name": "ag-52-to-53-1727693226",
  "properties": {
    ...
    "provisioningState": "Succeeded",
    "templateHash": "8563661129594839654",
    "templateLink": null,
    "timestamp": "2024-09-30T10:51:24.854150+00:00",
    "validatedResources": null
  },
  "resourceGroup": "ag-52-to-443",
  "tags": null,
  "type": "Microsoft.Resources/deployments"
}
```
### Connectivity Test
```shell
$  dig -p 52 www.google.com @172.167.124.181

; <<>> DiG 9.10.6 <<>> -p 52 www.google.com @172.167.124.181
;; global options: +cmd
;; connection timed out; no servers could be reached
```
## ag-53-to-443-not-working.bicep
THis example fails to create.
### Bicep Apply
```shell
az group create --name ag-53-to-443 --location "UK South"
az deployment group create \
  --name ag-53-to-443-$(date +%s) \
  --resource-group ag-53-to-443 \
  --template-file ag-53-to-443-not-working.bicep
  {
    "status":"Failed",
    "error": {
      "code":"DeploymentFailed",
      "target":"/subscriptions/GUID/resourceGroups/ag-53-to-443/providers/Microsoft.Resources/deployments/ag-53-to-443-1727693579",
      "message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
      "details": [
        {
          "code":"ResourceDeploymentFailure",
          "target":"/subscriptions/GUID/resourceGroups/ag-53-to-443/providers/Microsoft.Resources/deployments/ag53To443",
          "message":"The resource write operation failed to complete successfully, because it reached terminal provisioning state 'Failed'.",
          "details": [
            {  
              "code":"DeploymentFailed",
              "target":"/subscriptions/GUID/resourceGroups/ag-53-to-443/providers/Microsoft.Resources/deployments/ag53To443",
              "message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
              "details": [
                {
                  "code":"ResourceDeploymentFailure",
                  "target":"/subscriptions/GUID/resourceGroups/ag-53-to-443/providers/Microsoft.Network/applicationGateways/ag53To443ApplicationGateway",
                  "message":"The resource write operation failed to complete successfully, because it reached terminal provisioning state  'Failed'.",
                  "details": [ 
                    {
                      "code":"InternalServerError",
                      "message":"An error occurred.",
                      "details": []
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }
```
## ag-53-to-53-not-working.bicep
This example fails to create.
### Bicep Apply
```shell
az group create --name ag-53-to-53 --location "UK South"
az deployment group create \
  --name ag-53-to-53-$(date +%s) \
  --resource-group ag-53-to-53 \
  --template-file ag-53-to-53-not-working.bicep
  {
    "status":"Failed",
    "error": {
      "code":"DeploymentFailed",
      "target":"/subscriptions/GUID/resourceGroups/ag-53-to-53/providers/Microsoft.Resources/deployments/ag-53-to-53-1727694836",
      "message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
      "details": [
        {
          "code":"ResourceDeploymentFailure",
          "target":"/subscriptions/GUID/resourceGroups/ag-53-to-53/providers/Microsoft.Resources/deployments/ag53To53",
          "message":"The resource write operation failed to complete successfully, because it reached terminal provisioning state 'Failed'.",
          "details": [
            {
              "code":"DeploymentFailed","
              target":"/subscriptions/GUID/resourceGroups/ag-53-to-53/providers/Microsoft.Resources/deployments/ag53To53",
              "message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
              "details": [
                {
                  "code":"ResourceDeploymentFailure",
                  "target":"/subscriptions/GUID/resourceGroups/ag-53-to-53/providers/Microsoft.Network/applicationGateways/ag53To53ApplicationGateway",
                  "message":"The resource write operation failed to complete successfully, because it reached terminal provisioning state 'Failed'.",
                  "details": [
                    {
                      "code":"InternalServerError",
                      "message":"An error occurred.",
                      "details": []
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }
```


