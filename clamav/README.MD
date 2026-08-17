# Helm chart for ClamAV

## Introduction

This Helm chart deploys [ClamAV](https://www.clamav.net) on Kubernetes using the official
[`clamav/clamav`](https://hub.docker.com/r/clamav/clamav) image.

One pod runs `clamd` and, unless disabled, `freshclam` alongside it; `clamav-milter` is optional.

| Port    | Process         | Purpose                             |
|---------|-----------------|-------------------------------------|
| `3310`  | clamd           | Scan protocol (`INSTREAM`, probes)  |
| `7357`  | clamav-milter   | Milter endpoint, only when enabled  |

`clamd` binds its TCP socket only after the signature database is loaded, which takes minutes on a
cold start. The startup probe covers that window, so the liveness probe does not restart the pod
while the database is still loading.

## Values

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `replicaCount` | int | `1` | Number of replicas (ignored when `hpa.enabled`) |
| `image.repository` | string | `clamav/clamav` | Image repository |
| `image.pullPolicy` | string | `IfNotPresent` | Image pull policy |
| `image.tag` | string | `""` | Image tag, defaults to the chart `appVersion` |
| `imagePullSecrets` | list | `[]` | Image pull secrets |
| `nameOverride` | string | `""` | Override the chart name |
| `fullnameOverride` | string | `""` | Override the full resource name |
| `serviceAccount.create` | bool | `true` | Create a service account |
| `serviceAccount.annotations` | object | `{}` | Annotations of the service account |
| `serviceAccount.name` | string | `""` | Service account name, generated when empty |
| `podAnnotations` | object | `{}` | Annotations added to the pods |
| `podLabels` | object | `{}` | Labels added to the pods |
| `podSecurityContext` | object | `fsGroup: 101` | Pod-level security context (`101` is the `clamav` group in the image) |
| `securityContext` | object | `{}` | Container-level security context |
| `service.type` | string | `ClusterIP` | Service type |
| `service.port` | int | `3310` | Service port of clamd |
| `service.milterPort` | int | `7357` | Service port of clamav-milter, only added when `milter.enabled` |
| `service.annotations` | object | `{}` | Annotations of the service |
| `startupProbe.enabled` | bool | `true` | Enable the startup probe (TCP on the clamd port) |
| `startupProbe.initialDelaySeconds` / `timeoutSeconds` / `periodSeconds` / `failureThreshold` | int | `30` / `5` / `10` / `60` | Startup probe timing, the default allows ~10 minutes for the first database load |
| `livenessProbe.enabled` | bool | `true` | Enable the liveness probe (TCP on the clamd port) |
| `livenessProbe.initialDelaySeconds` / `timeoutSeconds` / `periodSeconds` / `failureThreshold` | int | `30` / `5` / `60` / `3` | Liveness probe timing |
| `readinessProbe.enabled` | bool | `true` | Enable the readiness probe (`clamdcheck.sh`, a real `PING` to clamd) |
| `readinessProbe.initialDelaySeconds` / `timeoutSeconds` / `periodSeconds` / `failureThreshold` | int | `30` / `5` / `30` / `3` | Readiness probe timing |
| `resources` | object | `{}` | Resource requests/limits. Required for CPU/memory based HPA. clamd needs well above 1Gi for the loaded database |
| `hpa.enabled` | bool | `false` | Enable HorizontalPodAutoscaler (`autoscaling/v2`). When enabled, `replicas` is not set on the Deployment |
| `hpa.minReplicas` | int | `1` | Minimum number of replicas |
| `hpa.maxReplicas` | int | `5` | Maximum number of replicas |
| `hpa.targetCPUUtilizationPercentage` | int | `80` | Target average CPU utilization, leave empty to disable the CPU metric |
| `hpa.targetMemoryUtilizationPercentage` | int | `nil` | Target average memory utilization, leave empty to disable the memory metric |
| `hpa.metrics` | list | `[]` | Extra raw metrics in `autoscaling/v2` format |
| `hpa.behavior` | object | `{}` | Scaling behavior in `autoscaling/v2` format |
| `pdb.enabled` | bool | `false` | Create a PodDisruptionBudget. Only useful with more than one replica |
| `pdb.minAvailable` | int/string | `nil` | Minimum available pods, takes precedence over `maxUnavailable` |
| `pdb.maxUnavailable` | int/string | `1` | Maximum unavailable pods, ignored when `minAvailable` is set |
| `pdb.unhealthyPodEvictionPolicy` | string | `""` | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes >= 1.27) |
| `priorityClassName` | string | `""` | Priority class of the pods |
| `terminationGracePeriodSeconds` | string | `""` | Termination grace period |
| `nodeSelector` | object | `{}` | Node selector of the pods |
| `tolerations` | list | `[]` | Tolerations of the pods |
| `affinity` | object | `{}` | Affinity/anti-affinity rules |
| `topologySpreadConstraints` | list | `[]` | Topology spread constraints |
| `env` | list | `[]` | Extra environment variables of the container |
| `envFrom` | list | `[]` | Extra ConfigMaps/Secrets exposed as environment variables |
| `clamd.tcpAddr` | string | `0.0.0.0` | clamd TCP bind address inside the pod |
| `clamd.tcpPort` | int | `3310` | clamd TCP port |
| `clamd.maxFileSize` | string | `100M` | Largest file that is scanned, larger files are skipped |
| `clamd.maxScanSize` | string | `400M` | Largest amount of data scanned per file |
| `clamd.streamMaxLength` | string | `100M` | Maximum size of a single `INSTREAM` upload |
| `clamd.maxThreads` | int | `12` | Number of clamd worker threads |
| `clamd.readTimeout` | int | `300` | Seconds clamd waits on an idle connection |
| `clamd.logVerbose` | bool | `false` | Verbose clamd logging |
| `clamd.alertOnEncryptedDoc` | bool | `false` | Treat encrypted documents as an alert |
| `clamd.alertOnEncryptedArchive` | bool | `false` | Treat encrypted archives as an alert |
| `clamd.extraConfig` | string | `""` | Additional raw `clamd.conf` configuration |
| `freshclam.enabled` | bool | `true` | Run freshclam inside the pod. Turning this off freezes the signature database |
| `freshclam.checks` | int | `12` | Database update checks per day |
| `freshclam.databaseMirror` | string | `database.clamav.net` | Mirror to fetch signatures from |
| `freshclam.privateMirror` | string | `""` | Optional private mirror, tried before `databaseMirror` |
| `freshclam.httpProxyServer` | string | `""` | Optional HTTP proxy for the database download |
| `freshclam.httpProxyPort` | string | `""` | Proxy port |
| `freshclam.httpProxyUsername` | string | `""` | Proxy username |
| `freshclam.httpProxyPassword` | string | `""` | Proxy password, rendered into a Secret. Mutually exclusive with `freshclam.existingSecret` |
| `freshclam.existingSecret` | string | `""` | Existing Secret holding the proxy password. An init container injects it into `freshclam.conf` before clamd starts |
| `freshclam.existingSecretPasswordKey` | string | `password` | Key inside `freshclam.existingSecret` |
| `freshclam.extraConfig` | string | `""` | Additional raw `freshclam.conf` configuration |
| `milter.enabled` | bool | `false` | Run clamav-milter and expose its port on the Service |
| `milter.tcpAddr` | string | `0.0.0.0` | Milter bind address |
| `milter.tcpPort` | int | `7357` | Milter port |
| `milter.clamdSocket` | string | `tcp:127.0.0.1:3310` | Where the milter reaches clamd |
| `milter.logVerbose` | bool | `false` | Verbose milter logging |
| `milter.extraConfig` | string | `""` | Additional raw `clamav-milter.conf` configuration |
| `persistence.enabled` | bool | `false` | Persist `/var/lib/clamav` (signature database). Uses an `emptyDir` when disabled |
| `persistence.existingClaim` | string | `""` | Use an existing PVC instead of creating one |
| `persistence.accessMode` | string | `ReadWriteOnce` | Access mode of the created PVC |
| `persistence.size` | string | `3Gi` | Size of the created PVC |
| `persistence.storageClass` | string | `""` | Storage class of the created PVC |
| `persistence.annotations` | object | `{}` | Annotations of the created PVC |

## Example

```yaml
replicaCount: 2

resources:
  limits:
    cpu: 2
    memory: 3Gi
  requests:
    cpu: 500m
    memory: 2Gi

pdb:
  enabled: true
  maxUnavailable: 1

persistence:
  enabled: false

clamd:
  maxFileSize: 50M
  maxScanSize: 200M
  streamMaxLength: 50M
```

Scan a file from another pod:

```bash
clamdscan --stream --config-file /dev/null --host <release>-clamav.<namespace>.svc.cluster.local
```

Point Postfix at the milter (`milter.enabled: true`):

```
smtpd_milters = inet:<release>-clamav.<namespace>.svc.cluster.local:7357
```

## Notes

- `persistence.accessMode: ReadWriteOnce` cannot be shared by multiple replicas on different nodes. Use a
  `ReadWriteMany` class, an `existingClaim` on shared storage, or keep `persistence.enabled: false` when scaling out.
- With `persistence.enabled: false` every new pod downloads the full signature database (several hundred MB)
  before clamd is ready, and each replica does so on its own. Beyond a handful of replicas, point
  `freshclam.privateMirror` at a local mirror to avoid being rate limited by `database.clamav.net`.
- `freshclam.enabled: false` requires a database that already exists in the volume — a fresh, empty
  `/var/lib/clamav` leaves clamd with nothing to load and it will not start.
