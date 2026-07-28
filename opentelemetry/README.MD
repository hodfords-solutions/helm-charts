# Helm chart for OpenTelemetry

## Introduction
This Helm chart deploys an `OpenTelemetryCollector` and an `Instrumentation` resource, both managed by the
OpenTelemetry Operator.

- The collector config is passed through as-is, so any receiver/processor/exporter supported by the collector image works
- The `Instrumentation` resource can be created in one or several workload namespaces

## Prerequisites
- https://github.com/open-telemetry/opentelemetry-operator

## Values

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | `my-collector` | Name of the OpenTelemetryCollector resource |
| `secret.enabled` | bool | `false` | Create a Secret with credentials used by the collector |
| `secret.name` | string | `""` | Name of the Secret (defaults to `<name>-secret`) |
| `secret.data` | object | `{}` | Key/value pairs written to the Secret `stringData` |
| `collector.enabled` | bool | `true` | Create the OpenTelemetryCollector resource |
| `collector.namespace` | string | `""` | Namespace of the collector (defaults to the release namespace) |
| `collector.mode` | string | `deployment` | `deployment`, `daemonset`, `statefulset` or `sidecar` |
| `collector.replicas` | int | `1` | Number of collector replicas |
| `collector.image` | string | `""` | Override the collector image |
| `collector.imagePullPolicy` | string | `""` | Image pull policy |
| `collector.serviceAccount` | string | `""` | Service account used by the collector pods |
| `collector.labels` | object | `{}` | Extra labels on the collector resource |
| `collector.annotations` | object | `{}` | Extra annotations on the collector resource |
| `collector.podAnnotations` | object | `{}` | Annotations added to the collector pods |
| `collector.env` | list | `[]` | Environment variables of the collector container |
| `collector.envFrom` | list | `[]` | Environment variables loaded from ConfigMaps/Secrets |
| `collector.resources` | object | `{}` | Resource requests/limits |
| `collector.args` | object | `{}` | Extra command line arguments |
| `collector.ports` | list | `[]` | Extra service ports |
| `collector.volumes` | list | `[]` | Extra volumes |
| `collector.volumeMounts` | list | `[]` | Extra volume mounts |
| `collector.volumeClaimTemplates` | list | `[]` | Volume claim templates (statefulset mode) |
| `collector.podSecurityContext` | object | `{}` | Pod-level security context |
| `collector.securityContext` | object | `{}` | Container-level security context |
| `collector.priorityClassName` | string | `""` | Priority class of the pods |
| `collector.terminationGracePeriodSeconds` | string | `""` | Termination grace period |
| `collector.nodeSelector` | object | `{}` | Node selector of the pods |
| `collector.tolerations` | list | `[]` | Tolerations of the pods |
| `collector.affinity` | object | `{}` | Affinity/anti-affinity rules |
| `collector.topologySpreadConstraints` | list | `[]` | Topology spread constraints |
| `collector.autoscaler` | object | `{}` | Horizontal autoscaling settings |
| `collector.ingress` | object | `{}` | Ingress settings of the collector |
| `collector.targetAllocator` | object | `{}` | Target allocator settings |
| `collector.observability` | object | `{}` | Observability (self-monitoring) settings |
| `collector.config` | object | otlp receiver + debug exporter | Collector configuration, rendered into `spec.config` |
| `instrumentations` | list | one default entry | One entry per Instrumentation resource |
| `instrumentations[].enabled` | bool | `true` | Create this Instrumentation resource |
| `instrumentations[].name` | string | `""` | Name of the resource (defaults to `<name>-instrumentation`, suffixed with the index from the second entry on) |
| `instrumentations[].namespace` | string | `""` | Namespace of the resource (defaults to the release namespace) |
| `instrumentations[].namespaces` | list | `[]` | Create the same resource in several namespaces (takes precedence over `namespace`) |
| `instrumentations[].labels` | object | `{}` | Extra labels on the resource |
| `instrumentations[].annotations` | object | `{}` | Extra annotations on the resource |
| `instrumentations[].exporter.endpoint` | string | `http://my-collector-collector.opentelemetry.svc:4318` | Endpoint the instrumented apps export to |
| `instrumentations[].exporter.tls` | object | `{}` | TLS settings of the exporter |
| `instrumentations[].propagators` | list | `[tracecontext, baggage, b3]` | Context propagators |
| `instrumentations[].sampler` | object | `{type: always_on}` | Sampler type and argument |
| `instrumentations[].resource` | object | `{}` | Resource attributes added to the telemetry |
| `instrumentations[].env` | list | `[]` | Environment variables injected into the instrumented containers |
| `instrumentations[].java` | object | `{}` | Java auto-instrumentation overrides |
| `instrumentations[].nodejs` | object | `{}` | Node.js auto-instrumentation overrides |
| `instrumentations[].python` | object | `{}` | Python auto-instrumentation overrides |
| `instrumentations[].dotnet` | object | `{}` | .NET auto-instrumentation overrides |
| `instrumentations[].go` | object | `{}` | Go auto-instrumentation overrides |
| `instrumentations[].apacheHttpd` | object | `{}` | Apache HTTPD auto-instrumentation overrides |
| `instrumentations[].nginx` | object | `{}` | Nginx auto-instrumentation overrides |

> `instrumentations` is a list, so `--set`/extra values files replace it entirely instead of merging entry by entry.

## Example

```yaml
name: my-collector

collector:
  namespace: opentelemetry
  mode: deployment
  env:
    - name: LANGFUSE_AUTH_STRING
      valueFrom:
        secretKeyRef:
          name: langfuse-otel-auth
          key: AUTH_STRING
  config:
    receivers:
      otlp:
        protocols:
          grpc: {}
          http: {}
    processors:
      tail_sampling:
        policies:
          - name: latency-sampling
            type: latency
            latency:
              threshold_ms: 1000
      filter/langfuse:
        error_mode: ignore
        traces:
          span:
            - 'not IsMatch(resource.attributes["service.name"], "^(backend-)?(pulse-agent|ai-gateway)(-cli)?$")'
    exporters:
      otlp:
        endpoint: tempo.tool-dev.svc.cluster.local:4317
        tls:
          insecure: true
      debug:
        verbosity: detailed
      otlphttp/langfuse:
        endpoint: https://langfuse.dev.hodfords.uk/api/public/otel
        headers:
          Authorization: 'Basic ${env:LANGFUSE_AUTH_STRING}'
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [tail_sampling]
          exporters: [otlp, debug]
        traces/langfuse:
          receivers: [otlp]
          processors: [filter/langfuse]
          exporters: [otlphttp/langfuse]

instrumentations:
  - name: my-instrumentation
    namespace: employer-dev
    exporter:
      endpoint: http://my-collector-collector.opentelemetry.svc:4318
    propagators:
      - tracecontext
      - baggage
      - b3
    sampler:
      type: always_on

  # A second Instrumentation, shared by several namespaces and sampling 25% of the traces
  - name: sampled-instrumentation
    namespaces:
      - backend-dev
      - worker-dev
    exporter:
      endpoint: http://my-collector-collector.opentelemetry.svc:4318
    sampler:
      type: parentbased_traceidratio
      argument: '0.25'
```

Instrumenting a workload is then a matter of adding the annotation to the pod template, for example:

```yaml
metadata:
  annotations:
    instrumentation.opentelemetry.io/inject-nodejs: 'employer-dev/my-instrumentation'
```
