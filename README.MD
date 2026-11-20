
| Parameter                 | Description                                                                                                                                                                                          | Default Value                               |
|---------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------|
| `name`                    | Application name                                                                                                                                                                                     | `application-name`                          |
| `replicaCount`            | Number of replicas (ignored if HPA is enabled)                                                                                                                                                       | `1`                                         |
| `dockerConfig.enabled`     | Enable Docker configuration                                                                                                                                                                          | `true`                                      |
| `dockerConfig.data`        | Docker config data (optional)                                                                                                                                                                        | `""`                                        |
| `service.type`             | Main service type (`ClusterIP`, `NodePort`, `LoadBalancer`)                                                                                                                                          | `ClusterIP`                                 |
| `service.port`             | Main service port, can be set by `APP_PORT` environment variable                                                                                                                                     | `3000`                                      |
| `service.externalTrafficPolicy` | `Cluster` or `Local`, only for `NodePort`/`LoadBalancer`. `Local` keeps the client source IP, but only nodes running a pod receive traffic. Also settable per entry in `services[]` | `""`                                        |
| `grpcService.enabled`      | Enable GRPC service                                                                                                                                                                                  | `false`                                     |
| `grpcService.port`         | GRPC service port, can be set by `GRPC_PORT` environment variable                                                                                                                                    | `3001`                                      |
| `image.repository`         | Docker image repository URL                                                                                                                                                                          | `ghcr.io/hodfords-solutions/api-gateway`    |
| `image.pullPolicy`         | Image pull policy                                                                                                                                                                                    | `IfNotPresent`                              |
| `image.tag`                | Image tag                                                                                                                                                                                            | `build-11089985823`                         |
| `queue.enabled`            | Enable queue service (deployment without exposed ports)                                                                                                                                              | `false`                                     |
| `queue.replicaCount`       | Number of queue replicas, falls back to `replicaCount` (ignored if `queueHpa.enabled`)                                                                                                               | `nil`                                       |
| `resources`                | Resource requests/limits of the container. Required for CPU/memory based HPA                                                                                                                         | `{}`                                        |
| `hpa.enabled`              | Enable HorizontalPodAutoscaler (`autoscaling/v2`) for the main deployment. When enabled, `replicas` is not set on the Deployment                                                                      | `false`                                     |
| `hpa.minReplicas`          | Minimum number of replicas                                                                                                                                                                           | `1`                                         |
| `hpa.maxReplicas`          | Maximum number of replicas                                                                                                                                                                           | `5`                                         |
| `hpa.targetCPUUtilizationPercentage`    | Target average CPU utilization, leave empty to disable the CPU metric                                                                                                                   | `80`                                        |
| `hpa.targetMemoryUtilizationPercentage` | Target average memory utilization, leave empty to disable the memory metric                                                                                                             | `nil`                                       |
| `hpa.metrics`              | Extra raw metrics in `autoscaling/v2` format, appended to the generated ones                                                                                                                         | `[]`                                        |
| `hpa.behavior`             | Scaling behavior in `autoscaling/v2` format                                                                                                                                                          | `{}`                                        |
| `queueHpa`                 | HorizontalPodAutoscaler for the queue deployment, same schema as `hpa`. Only rendered when `queue.enabled` is `true`                                                                                 | `enabled: false`                            |
| `pdb.enabled`              | Enable PodDisruptionBudget (`policy/v1`) for the main deployment. Only useful with more than one replica                                                                                              | `false`                                     |
| `pdb.minAvailable`         | Minimum available pods, takes precedence over `maxUnavailable`                                                                                                                                       | `nil`                                       |
| `pdb.maxUnavailable`       | Maximum unavailable pods, ignored when `minAvailable` is set                                                                                                                                         | `1`                                         |
| `pdb.unhealthyPodEvictionPolicy` | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes >= 1.27)                                                                                                                                        | `nil`                                       |
| `queuePdb`                 | PodDisruptionBudget for the queue deployment, same schema as `pdb`. Only rendered when `queue.enabled` is `true`                                                                                     | `enabled: false`                            |
| `healthCheck.enabled`      | Enable health checks                                                                                                                                                                                 | `false`                                     |
| `ingress.enabled`          | Enable ingress for the application                                                                                                                                                                   | `true`                                      |
| `ingress.className`        | Ingress class name                                                                                                                                                                                   | `nginx`                                     |
| `ingress.annotations`      | Additional annotations for the ingress                                                                                                                                                               | `` |
| `ingress.tls`              | TLS configuration for ingress                                                                                                                                                                        | `` |
| `ingress.host`             | Ingress host name                                                                                                                                                                                    | `app.example.com`                           |
| `certificate.enabled`     | Create a cert-manager `Certificate` for the gateway hostnames (secret `<fullname>-tls` unless `certificate.secretName`)                                                                                 | `false`                                     |
| `certificate.issuer.kind / .name` | Issuer of the certificate, e.g. `ClusterIssuer` / `letsencrypt-prod-cluster`                                                                                                                            | `ClusterIssuer` / `""`                      |
| `certificate.domain / .additionalHosts` | commonName (defaults to the first hostname) and extra SANs                                                                                                                                              | `""` / `[]`                                 |
| `listenerset.enabled`     | Create a Gateway API `ListenerSet` bringing one HTTPS listener per hostname onto a shared Gateway (Istio ingress gateway), same as the argo-cd chart's `server.listenerset`                             | `false`                                     |
| `listenerset.parentRef`   | The shared Gateway, e.g. `{name: tool-gateway, namespace: istio-ingress}`. Its `allowedListeners` must allow the release namespace                                                                      | `{}`                                        |
| `listenerset.listeners`   | Listeners used verbatim instead of the synthesized ones                                                                                                                                                 | `[]`                                        |
| `httproute.enabled`       | Create an `HTTPRoute` to the application service, attached to this release's ListenerSet unless `httproute.parentRefs` is set                                                                           | `false`                                     |
| `httproute.hostnames`     | Hostnames of the route, listener and certificate. Defaults to `ingress.host` + `ingress.hosts`                                                                                                          | `[]`                                        |
| `httproute.serviceName / .servicePort` | Backend of the route, defaults to `ingress.serviceName` / `ingress.servicePort`                                                                                                                         | `nil`                                       |
| `httproute.rules`         | Rules (`matches`/`filters`/`timeouts`), each routing to the backend                                                                                                                                     | `PathPrefix /`                              |
| `httproute.httpsRedirect.enabled / .parentRefs` | Also create an HTTP -> HTTPS redirect route on the Gateway's plain HTTP listener (`parentRefs` required)                                                                                                | `false` / `[]`                              |
| `imagePullSecrets`         | Extra image pull secrets (optional)                                                                                                                                                                  | `[]`                                        |
| `env`                      | Environment variables for the deployment                                                                                                                                                             | `[]`                                        |
| `externalSecrets`                      | External Secret Variables <br> <code>- clusterStoreName: cluster-name<br>&nbsp;&nbsp;refSecretName: secret-name<br> &nbsp;&nbsp;secrets:<br> &nbsp;&nbsp;&nbsp;&nbsp;DB_PASSWORD: db-password</code> | `[]`                                        |


## Migrating from ingress-nginx to the Istio gateway (Gateway API)

Hostnames and backend are taken from the existing `ingress` values, so a release migrates by turning
`ingress` off and the gateway resources on:

```yaml
ingress:
  enabled: false          # host/hosts/serviceName/servicePort are still read by httproute
  host: api.example.com
certificate:
  enabled: true
  issuer:
    name: letsencrypt-prod-cluster
listenerset:
  enabled: true
  parentRef:
    name: tool-gateway
    namespace: istio-ingress
httproute:
  enabled: true
  httpsRedirect:
    enabled: true
    parentRefs:
      - name: tool-gateway
        namespace: istio-ingress
        sectionName: http
```

The shared Gateway must list the release namespace in `spec.allowedListeners` and in its `http` listener's
`allowedRoutes` (redirect and cert-manager HTTP-01 routes). nginx annotations (IP allow-lists, body size,
timeouts...) do not carry over: use an Istio `AuthorizationPolicy` on the gateway and `httproute.rules[].timeouts`.
