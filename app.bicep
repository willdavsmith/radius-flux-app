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
      'Applications.Datastores/sqlDatabases': {
        default: {
          templateKind: 'bicep'
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/sqldatabases:latest'
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
  name: 'flux-demo-frontend'
  properties: {
    application: app.id
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3000
        }
      }
    }
  }
}

resource gateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'flux-demo-gateway'
  properties: {
    application: app.id
    hostname: {
      fullyQualifiedHostname: 'localhost:8080'
    }
    routes: [
      {
        path: '/'
        destination: 'http://${frontend.name}:3000'
      }
    ]
  }
}
