
| Parameter                 | Description                                                       | Default Value                               |
|---------------------------|-------------------------------------------------------------------|---------------------------------------------|
| `name`                    | Application name                                                  | `application-name`                          |
| `replicaCount`            | Number of replicas (ignored if HPA is enabled)                    | `1`                                         |
| `dockerConfig.enabled`     | Enable Docker configuration                                       | `true`                                      |
| `dockerConfig.data`        | Docker config data (optional)                                     | `""`                                        |
| `service.type`             | Main service type (`ClusterIP`, `NodePort`, `LoadBalancer`)       | `ClusterIP`                                 |
| `service.port`             | Main service port, can be set by `APP_PORT` environment variable  | `3000`                                      |
| `grpcService.enabled`      | Enable GRPC service                                               | `false`                                     |
| `grpcService.port`         | GRPC service port, can be set by `GRPC_PORT` environment variable | `3001`                                      |
| `image.repository`         | Docker image repository URL                                       | `ghcr.io/hodfords-solutions/api-gateway`    |
| `image.pullPolicy`         | Image pull policy                                                 | `IfNotPresent`                              |
| `image.tag`                | Image tag                                                         | `build-11089985823`                         |
| `queue.enabled`            | Enable queue service (deployment without exposed ports)           | `false`                                     |
| `healthCheck.enabled`      | Enable health checks                                              | `false`                                     |
| `ingress.enabled`          | Enable ingress for the application                                | `true`                                      |
| `ingress.className`        | Ingress class name                                                | `nginx`                                     |
| `ingress.annotations`      | Additional annotations for the ingress                            | `` |
| `ingress.tls`              | TLS configuration for ingress                                     | `` |
| `ingress.host`             | Ingress host name                                                 | `app.example.com`                           |
| `imagePullSecrets`         | Extra image pull secrets (optional)                               | `[]`                                        |
| `env`                      | Environment variables for the deployment                          | `[]`                                        |

