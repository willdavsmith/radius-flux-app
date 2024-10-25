// Import the set of Radius resources (Applications.*) into Bicep
extension radius

param port int
param tag string
param prefix string
param kubernetesNamespace string

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: '${prefix}-env'
  properties: {
    compute: {
      kind: 'kubernetes'
      namespace: kubernetesNamespace
    }
    recipes: {
      'Applications.Datastores/redisCaches': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/rediscaches:${tag}'
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: '${prefix}-app'
  properties: {
    environment: env.id
  }
}

resource ctnr 'Applications.Core/containers@2023-10-01-preview' = {
  name: '${prefix}-ctnr'
  properties: {
    application: app.id
    container: {
      image: 'ghcr.io/radius-project/samples/demo:${tag}'
      ports: {
        web: {
          containerPort: port
        }
      }
    }
    connections: {
      redis: {
        source: db.id
      }
    }
  }
}

resource db 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: '${prefix}-db'
  properties: {
    application: app.id
    environment: env.id
  }
}
