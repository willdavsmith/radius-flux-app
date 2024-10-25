// Import the set of Radius resources (Applications.*) into Bicep
extension radius

param port int
param tag string

resource demoenv 'Applications.Core/environments@2023-10-01-preview' = {
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
          templatePath: 'ghcr.io/radius-project/recipes/local-dev/rediscaches:${tag}'
        }
      }
    }
  }
}

resource demoapp 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'demoapp'
  properties: {
    environment: demoenv.id
  }
}

resource democtnr 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'democtnr'
  properties: {
    application: demoapp.id
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
        source: demodb.id
      }
    }
  }
}

resource demodb 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'demodb'
  properties: {
    application: demoapp.id
    environment: demoenv.id
  }
}
