# Helm chart for MongoDB

## Introduction
This Helm chart deploys a MongoDB database on a Kubernetes cluster using MCK (Mongodb Controllers for Kubernetes)

- Just working with MongoDBCommunity

## Prerequisites
- https://github.com/mongodb/mongodb-kubernetes

## Values

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | `mongodb` | Name of the MongoDBCommunity resource |
| `replicaCount` | int | `3` | Number of replica set members |
| `version` | string | `8.2.0` | MongoDB version |
| `labels` | object | `{}` | Extra labels on the MongoDBCommunity resource |
| `annotations` | object | `{}` | Extra annotations on the MongoDBCommunity resource |
| `auth.username` | string | `root` | Admin user name |
| `auth.password` | string | `""` | Admin password (stored in `<name>-mongodb-secret`) |
| `auth.scramCredentialsSecretName` | string | `my-scram` | Name used for the generated SCRAM credentials secret |
| `persistent.storageClass` | string | `""` | Storage class of the data volume |
| `persistent.size` | string | `3Gi` | Size of the data volume |
| `persistent.accessModes` | list | `[ReadWriteOnce]` | Access modes of the data volume |
| `log.persistent.storageClass` | string | `""` | Storage class of the logs volume |
| `log.persistent.size` | string | `1Gi` | Size of the logs volume |
| `log.persistent.accessModes` | list | `[ReadWriteOnce]` | Access modes of the logs volume |
| `additionalMongodConfig` | object | journalCompressor `zlib` | Extra mongod configuration |
| `mongod.resources` | object | `{}` | Resource requests/limits of the `mongod` container |
| `mongod.securityContext` | object | `{}` | Security context of the `mongod` container |
| `mongodbAgent.resources` | object | `{}` | Resource requests/limits of the `mongodb-agent` container |
| `mongodbAgent.securityContext` | object | `{}` | Security context of the `mongodb-agent` container |
| `mongot.enabled` | bool | `false` | Deploy MongoDB Search (mongot) as a `MongoDBSearch` resource (MCK >= 1.10, MongoDB >= 8.2.0) |
| `mongot.version` | string | `""` | mongot version, empty lets the operator pick |
| `mongot.logLevel` | string | `""` | `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` |
| `mongot.replicas` | int | `1` | Number of mongot pods, more than 1 requires `mongot.loadBalancer` |
| `mongot.resources` | object | `{}` | Resource requests/limits of the mongot pods |
| `mongot.persistent.storageClass` | string | `""` | Storage class of the mongot volume |
| `mongot.persistent.size` | string | `10Gi` | Size of the mongot volume |
| `mongot.jvmFlags` | list | `[]` | mongot `--jvm-flags` |
| `mongot.advancedConfigs` | object | `{}` | Extra mongot config, rendered under `advancedConfigs` |
| `mongot.nodeAffinity` | object | `{}` | Node affinity of the mongot pods |
| `mongot.loadBalancer` | object | `{}` | `managed` (Envoy) or `unmanaged` load balancer in front of mongot |
| `mongot.statefulSet` | object | `{}` | Overrides merged into the mongot StatefulSet |
| `mongot.syncSource.username` | string | `search-sync-source` | User mongot syncs data with, created with the `searchCoordinator` role |
| `mongot.syncSource.password` | string | `""` | Password of the sync user (stored in `<name>-search-sync-source-password`) |
| `mongot.syncSource.existingSecret` | string | `""` | Existing secret with a `password` key, used instead of `password` |
| `mongot.tls.certificateKeySecretName` | string | `""` | TLS secret of the mongot server, empty disables TLS |
| `mongot.observability` | object | `{}` | `spec.observability` of the `MongoDBSearch` resource |
| `serviceName` | string | `""` | Override the StatefulSet headless service name |
| `pdb.enabled` | bool | `false` | Create a PodDisruptionBudget for the replica set pods |
| `pdb.minAvailable` | int/string | `2` | Minimum available pods, takes precedence over `maxUnavailable` |
| `pdb.maxUnavailable` | int/string | `nil` | Maximum unavailable pods, ignored when `minAvailable` is set |
| `pdb.unhealthyPodEvictionPolicy` | string | `""` | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes >= 1.27) |
| `pdb.selectorLabels` | object | `{}` | Override the pod selector, defaults to `app: <serviceName\|name-svc>` |
| `podAnnotations` | object | `{}` | Annotations added to the pods |
| `podLabels` | object | `{}` | Labels added to the pods |
| `imagePullSecrets` | list | `[]` | Image pull secrets |
| `podSecurityContext` | object | `{}` | Pod-level security context |
| `priorityClassName` | string | `""` | Priority class of the pods |
| `terminationGracePeriodSeconds` | string | `""` | Termination grace period |
| `nodeSelector` | object | `{}` | Node selector of the pods |
| `tolerations` | list | `[]` | Tolerations of the pods |
| `affinity` | object | `{}` | Affinity/anti-affinity rules |
| `topologySpreadConstraints` | list | `[]` | Topology spread constraints |

## Example

```yaml
mongod:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi

nodeSelector:
  workload: database

tolerations:
  - key: 'database'
    operator: 'Equal'
    value: 'true'
    effect: 'NoSchedule'
```

### MongoDB Search (mongot)

```yaml
mongot:
  enabled: true
  resources:
    limits:
      cpu: '2'
      memory: 4Gi
    requests:
      cpu: '1'
      memory: 2Gi
  syncSource:
    password: 'change-me'
```
