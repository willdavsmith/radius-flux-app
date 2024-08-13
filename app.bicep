// Import the set of Radius resources (Applications.*) into Bicep
import radius as radius

resource env 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'flux-demo-env'
  properties: {
    compute: {
      kind: 'kubernetes'
      namespace: 'flux-demo'
    }
    recipes: {
      'Applications.Datastores/redisCaches': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/rediscaches:latest'
        }
      }
    }
  }
}

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'flux-demo-app'
  properties: {
    environment: env.id
  }
}

resource frontend 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'flux-demo-frontend1'
  properties: {
    application: app.id
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3001
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
  name: 'db'
  properties: {
    application: app.id
    environment: env.id
  }
}
