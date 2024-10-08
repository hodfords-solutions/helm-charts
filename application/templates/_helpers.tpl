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
{{- printf "%s-%s" .Values.queue.name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
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
