# Helm chart for Rspamd

## Introduction

This Helm chart deploys [Rspamd](https://rspamd.com) on Kubernetes using the official
[`rspamd/rspamd`](https://hub.docker.com/r/rspamd/rspamd) image.

It is modelled after [ectobit/charts/rspamd](https://github.com/ectobit/charts/tree/main/rspamd), with two differences:

- the image is the official `rspamd/rspamd` one instead of `ectobit/rspamd`;
- there is no embedded Redis sub-chart and **no custom Redis TLS support** — point `redis.*` at an existing
  Redis/Valkey service. If that backend needs TLS, terminate it in front of Rspamd (sidecar proxy, service mesh).

The Deployment exposes three workers:

| Port    | Worker              | Purpose                          |
|---------|---------------------|----------------------------------|
| `11332` | proxy (milter)      | Milter endpoint for Postfix/Exim |
| `11333` | normal              | Scan protocol                    |
| `11334` | controller          | Web UI / HTTP API, probes        |

Liveness/readiness probes call `GET /ping` on the controller, so `config.workerController.enabled` must stay `true`
and `config.workerController.bindSocket` must listen on the pod IP (default `*:11334`) when probes are enabled.

## Values

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `replicaCount` | int | `1` | Number of replicas (ignored when `hpa.enabled`) |
| `image.repository` | string | `rspamd/rspamd` | Image repository |
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
| `podSecurityContext` | object | `fsGroup: 101` | Pod-level security context (`101` is the `_rspamd` group in the image) |
| `securityContext` | object | `{}` | Container-level security context |
| `service.type` | string | `ClusterIP` | Service type |
| `service.proxyPort` | int | `11332` | Service port of the proxy/milter worker |
| `service.port` | int | `11333` | Service port of the normal worker |
| `service.controllerPort` | int | `11334` | Service port of the controller worker |
| `service.annotations` | object | `{}` | Annotations of the service |
| `livenessProbe.enabled` | bool | `true` | Enable the liveness probe (`GET /ping` on the controller) |
| `livenessProbe.initialDelaySeconds` / `timeoutSeconds` / `periodSeconds` | int | `10` / `5` / `60` | Liveness probe timing |
| `readinessProbe.enabled` | bool | `true` | Enable the readiness probe (`GET /ping` on the controller) |
| `readinessProbe.initialDelaySeconds` / `timeoutSeconds` / `periodSeconds` | int | `10` / `5` / `30` | Readiness probe timing |
| `resources` | object | `{}` | Resource requests/limits. Required for CPU/memory based HPA |
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
| `config.options` | string | `""` | Rendered to `/etc/rspamd/local.d/options.inc` |
| `config.arc` | string | `""` | Rendered to `/etc/rspamd/local.d/arc.conf` |
| `config.rbl` | string | `""` | Rendered to `/etc/rspamd/local.d/rbl.conf` |
| `config.settings` | string | `""` | Rendered to `/etc/rspamd/local.d/settings.conf` |
| `config.historyRedis.enabled` | bool | `true` | Render `history_redis.conf` when `redis.enabled` |
| `config.historyRedis.keyPrefix` | string | `rs_history{{HOSTNAME}}{{COMPRESS}}` | Redis history key prefix, expanded by Rspamd |
| `config.historyRedis.nrows` | int | `200` | Maximum number of Redis history rows |
| `config.historyRedis.compress` | bool | `true` | Enable Redis history compression |
| `config.historyRedis.subjectPrivacy` | bool | `false` | Enable Redis history subject privacy |
| `config.historyRedis.extraConfig` | string | `""` | Additional raw `history_redis` configuration |
| `config.workerController.enabled` | bool | `true` | Render `/etc/rspamd/local.d/worker-controller.inc` |
| `config.workerController.bindSocket` | string | `*:11334` | Controller bind socket, must be reachable by kubelet when probes are enabled |
| `config.workerController.secureIp` | list | `[127.0.0.1, ::1]` | IPs/CIDRs allowed to use the controller without a password |
| `config.workerController.password` | string | `""` | Controller password, rendered into a Secret instead of the ConfigMap |
| `config.workerController.enablePassword` | string | `""` | Controller enable password, rendered into a Secret instead of the ConfigMap |
| `config.workerController.extraConfig` | string | `""` | Additional raw controller worker configuration |
| `config.workerNormal.bindSocket` | string | `*:11333` | Normal worker bind socket |
| `config.workerNormal.extraConfig` | string | `""` | Additional raw normal worker configuration |
| `config.workerProxy.bindSocket` | string | `*:11332` | Proxy worker bind socket |
| `config.workerProxy.extraConfig` | string | `""` | Additional raw proxy worker configuration |
| `config.whitelist.ipMap` / `config.whitelist.fromMap` | string | `""` | Contents of `whitelist_ip.map` / `whitelist_from.map` |
| `config.blacklist.ipMap` / `config.blacklist.fromMap` | string | `""` | Contents of `blacklist_ip.map` / `blacklist_from.map` |
| `config.milterHeaders` | string | see `values.yaml` | Contents of `milter_headers.conf` |
| `config.dkimSelector` | string | `2020` | DKIM selector, keys read from `/var/lib/rspamd/dkim/$selector.key` |
| `config.multiMap` | string | see `values.yaml` | Contents of `multimap.conf` |
| `config.overrideClassifierBayes` | string | `autolearn = true;` | Contents of `override.d/classifier-bayes.conf` |
| `redis.enabled` | bool | `false` | Use an external Redis/Valkey backend. Enables the Redis bayes backend and history |
| `redis.host` | string | `""` | Redis/Valkey hostname, required when `redis.enabled` |
| `redis.port` | int | `6379` | Redis/Valkey port |
| `redis.db` | string | `""` | Optional Redis database number |
| `redis.username` | string | `""` | Optional Redis ACL username |
| `redis.password` | string | `""` | Optional Redis password, rendered into a Secret. Mutually exclusive with `redis.existingSecret` |
| `redis.existingSecret` | string | `""` | Existing Secret holding the Redis password. An init container injects it into the Redis config before Rspamd starts |
| `redis.existingSecretPasswordKey` | string | `password` | Key inside `redis.existingSecret` |
| `redis.timeout` | string | `""` | Optional Rspamd Redis timeout |
| `persistence.enabled` | bool | `false` | Persist `/var/lib/rspamd` (bayes/fuzzy/DKIM keys). Uses an `emptyDir` when disabled |
| `persistence.existingClaim` | string | `""` | Use an existing PVC instead of creating one |
| `persistence.accessMode` | string | `ReadWriteOnce` | Access mode of the created PVC |
| `persistence.size` | string | `1Gi` | Size of the created PVC |
| `persistence.storageClass` | string | `""` | Storage class of the created PVC |
| `persistence.annotations` | object | `{}` | Annotations of the created PVC |

## Example

```yaml
replicaCount: 2

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi

pdb:
  enabled: true
  maxUnavailable: 1

redis:
  enabled: true
  host: valkey-master.mail.svc.cluster.local
  existingSecret: valkey-auth
  existingSecretPasswordKey: password

config:
  workerController:
    password: '$2$...' # output of `rspamadm pw`
  options: |
    local_networks = "10.0.0.0/8";
```

Point Postfix at the milter worker:

```
smtpd_milters = inet:<release>-rspamd.<namespace>.svc.cluster.local:11332
```

## Notes

- `persistence.accessMode: ReadWriteOnce` cannot be shared by multiple replicas on different nodes. Use a
  `ReadWriteMany` class, an `existingClaim` on shared storage, or keep `persistence.enabled: false` when scaling out.
- Bayes statistics and history live in Redis when `redis.enabled` is `true`, which is what makes multiple replicas
  useful; without it each replica learns on its own.
