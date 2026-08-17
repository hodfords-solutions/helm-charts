{{/*
Expand the name of the chart.
*/}}
{{- define "backend.name" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "queue.name" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" }}-queue
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "backend.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := .Values.name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "backend.chart" -}}
{{- printf "%s-%s" .Values.name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "queue.chart" -}}
{{- printf "%s-%s" (include "queue.name" .) .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}


{{/*
Backend labels
*/}}
{{- define "backend.labels" -}}
helm.sh/chart: {{ include "backend.chart" . }}
{{ include "backend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Queue labels
*/}}
{{- define "queue.labels" -}}
helm.sh/chart: {{ include "queue.chart" . }}
{{ include "queue.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Backend selector labels
*/}}
{{- define "backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Queue selector labels
*/}}
{{- define "queue.selectorLabels" -}}
app.kubernetes.io/name: {{ include "queue.name" . }}
app.kubernetes.io/instance: {{ printf "%s-queue" .Release.Name }}
{{- end }}

{{/*
Normalized list of services, rendered as a yaml dict with an "items" key so that
consumers can read it back with fromYaml:

  {{- $services := (include "backend.services" . | fromYaml).items }}

Each item is a dict with name/type/annotations/ports. The first one is the main
service built from service/grpcService, the extra ones come from .Values.services and
are suffixed with their own name.
*/}}
{{- define "backend.services" -}}
{{- $fullName := include "backend.fullname" . -}}
{{- $ports := list (dict "name" "http" "port" .Values.service.port "protocol" "TCP") -}}
{{- if .Values.grpcService.enabled -}}
{{- $ports = append $ports (dict "name" "grpc" "port" .Values.grpcService.port "protocol" "TCP") -}}
{{- end -}}
{{- $services := list (dict
    "name" $fullName
    "type" .Values.service.type
    "annotations" (default dict .Values.service.annotations)
    "ports" $ports) -}}
{{- range $svc := .Values.services -}}
{{- $services = append $services (dict
    "name" (printf "%s-%s" $fullName $svc.name | trunc 63 | trimSuffix "-")
    "type" (default "ClusterIP" $svc.type)
    "annotations" (default dict $svc.annotations)
    "ports" (default list $svc.ports)) -}}
{{- end -}}
{{- toYaml (dict "items" $services) -}}
{{- end }}

{{/*
Container port of a service port: the target port when it is a number, the service
port itself when the target port is a named reference (or not set at all).
*/}}
{{- define "backend.containerPort" -}}
{{- if and (hasKey . "targetPort") (kindIs "float64" .targetPort) -}}
{{- .targetPort -}}
{{- else if and (hasKey . "targetPort") (kindIs "int" .targetPort) -}}
{{- .targetPort -}}
{{- else -}}
{{- .port -}}
{{- end -}}
{{- end }}

{{/*
Container ports for the main deployment, deduplicated by name and by port/protocol
across every service.
*/}}
{{- define "backend.containerPorts" -}}
{{- $services := (include "backend.services" . | fromYaml).items -}}
{{- $seenNames := dict -}}
{{- $seenPorts := dict -}}
{{- range $svc := $services -}}
{{- range $port := $svc.ports -}}
{{- $protocol := default "TCP" $port.protocol -}}
{{- $containerPort := include "backend.containerPort" $port -}}
{{- $portKey := printf "%s/%s" $containerPort $protocol -}}
{{- if and (not (hasKey $seenNames $port.name)) (not (hasKey $seenPorts $portKey)) -}}
{{- $_ := set $seenNames $port.name true -}}
{{- $_ := set $seenPorts $portKey true }}
- name: {{ $port.name }}
  containerPort: {{ $containerPort }}
  protocol: {{ $protocol }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Name of the secret backing a secretMounts entry: an external secret created by this
chart when secretName is not set, an already existing secret otherwise.
*/}}
{{- define "backend.secretMountName" -}}
{{- $fullName := include "backend.fullname" .context -}}
{{- with .mount.externalSecret -}}
{{- printf "%s-%s-secret" $fullName . -}}
{{- else -}}
{{- .mount.secretName -}}
{{- end -}}
{{- end }}

{{/*
Volume name of a secretMounts entry, indexed so that the same secret can be mounted
more than once.
*/}}
{{- define "backend.secretMountVolume" -}}
{{- printf "secret-%d-%s" (int .index) (include "backend.secretMountName" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Volumes for the secret files managed by this chart and for every secretMounts entry.
*/}}
{{- define "backend.volumes" -}}
{{- $fullName := include "backend.fullname" . -}}
{{- if and .Values.secretFiles.enabled .Values.secretFiles.files }}
- name: secret-files
  secret:
    secretName: {{ $fullName }}-files
    {{- with .Values.secretFiles.defaultMode }}
    defaultMode: {{ . }}
    {{- end }}
{{- end }}
{{- range $i, $mount := .Values.secretMounts }}
- name: {{ include "backend.secretMountVolume" (dict "index" $i "mount" $mount "context" $) }}
  secret:
    secretName: {{ include "backend.secretMountName" (dict "mount" $mount "context" $) }}
    {{- with $mount.defaultMode }}
    defaultMode: {{ . }}
    {{- end }}
    {{- if hasKey $mount "optional" }}
    optional: {{ $mount.optional }}
    {{- end }}
    {{- with $mount.items }}
    items:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Volume mounts matching "backend.volumes".
*/}}
{{- define "backend.volumeMounts" -}}
{{- if and .Values.secretFiles.enabled .Values.secretFiles.files }}
- name: secret-files
  mountPath: {{ .Values.secretFiles.mountPath }}
  readOnly: true
{{- end }}
{{- range $i, $mount := .Values.secretMounts }}
- name: {{ include "backend.secretMountVolume" (dict "index" $i "mount" $mount "context" $) }}
  mountPath: {{ $mount.mountPath }}
  {{- with $mount.subPath }}
  subPath: {{ . }}
  {{- end }}
  {{- if hasKey $mount "readOnly" }}
  readOnly: {{ $mount.readOnly }}
  {{- else }}
  readOnly: true
  {{- end }}
{{- end }}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Service and port the ingress routes to: the first port of the first service by
default, overridable with ingress.serviceName / ingress.servicePort. Rendered as a
yaml dict with name/port keys.
*/}}
{{- define "backend.ingressBackend" -}}
{{- $services := (include "backend.services" . | fromYaml).items -}}
{{- $service := first $services -}}
{{- with .Values.ingress.serviceName -}}
{{- $name := . -}}
{{- range $svc := $services -}}
{{- if or (eq $svc.name $name) (hasSuffix (printf "-%s" $name) $svc.name) -}}
{{- $service = $svc -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $port := (first $service.ports).port -}}
{{- with .Values.ingress.servicePort -}}
{{- if kindIs "string" . -}}
{{- $portName := . -}}
{{- range $p := $service.ports -}}
{{- if eq $p.name $portName -}}
{{- $port = $p.port -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- $port = . -}}
{{- end -}}
{{- end -}}
{{- toYaml (dict "name" $service.name "port" $port) -}}
{{- end }}
