extension radius

// Parameters -------------------------------------------------------

@description('Application name. Defaults to "eshop"')
param applicationName string = 'eshop'

@description('Container registry to pull from, with optional path. Defaults to "ghcr.io/radius-project/samples/eshop"')
param imageRegistry string = 'ghcr.io/radius-project/samples/eshop'

@description('Container image tag to use for eshop images. Defaults to "latest".')
param imageTag string = 'latest'

// Variables ---------------------------------------------------------

// Get the environment name from the environment ID
var environmentName = 'default'
resource eshopEnvironment 'Applications.Core/environments@2023-10-01-preview' existing = {
  name: environmentName
}

// Check if the environment has the rabbitmqqueues recipe registered
// If it does not, use Azure ServiceBus
var AZURESERVICEBUSENABLED = contains(eshopEnvironment.properties.recipes, 'Applications.Messaging/rabbitmqqueues') ? 'False' : 'True'

// Environment --------------------------------------------------------

resource environment 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'default'
  properties: {
    compute: {
      kind: 'kubernetes'
      namespace: 'default'
    }
    recipes: {
      'Applications.Datastores/redisCaches': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/rediscaches:latest'
        }
      }
      'Applications.Messaging/rabbitMQQueues': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/rabbitmqqueues:latest'
        }
      }
      'Applications.Datastores/sqlDatabases': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/sqldatabases:latest'
        }
      }
      'Applications.Dapr/pubSubBrokers': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/pubsubbrokers:latest'
        }
      }
      'Applications.Dapr/secretStores': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/secretstores:latest'
        }
      }
      'Applications.Dapr/stateStores': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/statestores:latest'
        }
      }
      'Applications.Datastores/mongoDatabases': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/mongodatabases:latest'
        }
      }
    }
  }
}

// Application --------------------------------------------------------

resource eshopApplication 'Applications.Core/applications@2023-10-01-preview' = {
  name: applicationName
  properties: {
    environment: environment.id
  }
}

// Infrastructure ------------------------------------------------------

module infra 'infra/infra.bicep' = {
  name: 'infra'
  params: {
    application: eshopApplication.id
    environment: environment.id
    AZURESERVICEBUSENABLED: AZURESERVICEBUSENABLED
  }
}

// Networking ----------------------------------------------------------

module networking 'infra/networking.bicep' = {
  name: 'networking'
  params: {
    application: eshopApplication.id
  }
}

// Services ------------------------------------------------------------

module basket 'services/basket.bicep' = {
  name: 'basket'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
    redisBasketName: infra.outputs.redisBasket
    eventBusConnectionString: infra.outputs.eventBusConnectionString
    AZURESERVICEBUSENABLED: AZURESERVICEBUSENABLED
  }
}

module catalog 'services/catalog.bicep' = {
  name: 'catalog'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
    sqlCatalogDbName: infra.outputs.sqlCatalogDb
    eventBusConnectionString: infra.outputs.eventBusConnectionString
    AZURESERVICEBUSENABLED: AZURESERVICEBUSENABLED
  }
}

module identity 'services/identity.bicep' = {
  name: 'identity'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
    redisKeystoreName: infra.outputs.redisKeystore
    sqlIdentityDbName: infra.outputs.sqlIdentityDb
  }
}

module ordering 'services/ordering.bicep' = {
  name: 'ordering'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
    redisKeystoreName: infra.outputs.redisKeystore
    sqlOrderingDbName: infra.outputs.sqlOrderingDb
    eventBusConnectionString: infra.outputs.eventBusConnectionString
    AZURESERVICEBUSENABLED: AZURESERVICEBUSENABLED
  }
}

module payment 'services/payment.bicep' = {
  name: 'payment'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    eventBusConnectionString: infra.outputs.eventBusConnectionString
    AZURESERVICEBUSENABLED: AZURESERVICEBUSENABLED
  }
}

module seq 'services/seq.bicep' = {
  name: 'seq'
  params: {
    application: eshopApplication.id
  }
}

module web 'services/web.bicep' = {
  name: 'web'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
    redisKeystoreName: infra.outputs.redisKeystore
  }
}

module webhooks 'services/webhooks.bicep' = {
  name: 'webhooks'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
    sqlWebhooksDbName: infra.outputs.sqlWebhooksDb
    eventBusConnectionString: infra.outputs.eventBusConnectionString
    AZURESERVICEBUSENABLED: AZURESERVICEBUSENABLED
  }
}

module webshopping 'services/webshopping.bicep' = {
  name: 'webshopping'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
    gatewayName: networking.outputs.gateway
  }
}

module webstatus 'services/webstatus.bicep' = {
  name: 'webstatus'
  params: {
    application: eshopApplication.id
    imageRegistry: imageRegistry
    imageTag: imageTag
  }
}
