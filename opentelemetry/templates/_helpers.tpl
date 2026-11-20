{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Namespace of the collector and of the Gateway API resources routing to it.
*/}}
{{- define "collector.namespace" -}}
{{- .Values.collector.namespace | default .Release.Namespace -}}
{{- end }}

{{/*
Service the operator creates for the collector.
*/}}
{{- define "collector.serviceName" -}}
{{- printf "%s-collector" (include "name" .) -}}
{{- end }}

{{/*
Hostnames served through the Gateway: collector.httproute.hostnames, or the operator
ingress hostname (collector.ingress.hostname) when empty. Rendered as a yaml dict with
an "items" key.
*/}}
{{- define "collector.gatewayHostnames" -}}
{{- $hosts := .Values.collector.httproute.hostnames | default (compact (list (.Values.collector.ingress | default dict).hostname)) -}}
{{- $out := list -}}
{{- range $hosts -}}
{{- $out = append $out (tpl (toString .) $) -}}
{{- end -}}
{{- toYaml (dict "items" (uniq $out)) -}}
{{- end }}

{{/*
Secret the Certificate writes to: collector.certificate.secretName, <name>-tls by default.
*/}}
{{- define "collector.certificateSecretName" -}}
{{- .Values.collector.certificate.secretName | default (printf "%s-tls" (include "name" .)) -}}
{{- end }}
