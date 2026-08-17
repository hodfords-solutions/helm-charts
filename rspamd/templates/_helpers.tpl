{{/*
Expand the name of the chart.
*/}}
{{- define "rspamd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "rspamd.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "rspamd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rspamd.labels" -}}
helm.sh/chart: {{ include "rspamd.chart" . }}
{{ include "rspamd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rspamd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rspamd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rspamd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rspamd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate Redis values.
*/}}
{{- define "rspamd.validateRedis" -}}
{{- if .Values.redis.enabled -}}
{{- if not .Values.redis.host -}}
{{- fail "redis.host is required when redis.enabled is true" -}}
{{- end -}}
{{- if and .Values.redis.password .Values.redis.existingSecret -}}
{{- fail "redis.password and redis.existingSecret cannot both be set" -}}
{{- end -}}
{{- if and .Values.redis.existingSecret (not .Values.redis.existingSecretPasswordKey) -}}
{{- fail "redis.existingSecretPasswordKey is required when redis.existingSecret is set" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Redis config Secret name.
*/}}
{{- define "rspamd.redisConfigSecretName" -}}
{{- printf "%s-redis-config" (include "rspamd.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Controller config Secret name.
*/}}
{{- define "rspamd.controllerConfigSecretName" -}}
{{- printf "%s-controller-config" (include "rspamd.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
True when the controller worker config holds a secret and must live in a Secret.
*/}}
{{- define "rspamd.controllerSecretEnabled" -}}
{{- if and .Values.config.workerController.enabled (or .Values.config.workerController.password .Values.config.workerController.enablePassword) -}}true{{- end -}}
{{- end }}

{{/*
Name of the volume holding the Redis config files.
*/}}
{{- define "rspamd.redisConfigVolume" -}}
{{- if .Values.redis.existingSecret -}}redis-config-rendered{{- else -}}redis-config{{- end -}}
{{- end }}

{{/*
Rspamd controller worker config.
*/}}
{{- define "rspamd.workerControllerConfig" -}}
bind_socket = {{ .Values.config.workerController.bindSocket | quote }};
{{- range .Values.config.workerController.secureIp }}
secure_ip = {{ . | quote }};
{{- end }}
{{- with .Values.config.workerController.password }}
password = {{ . | quote }};
{{- end }}
{{- with .Values.config.workerController.enablePassword }}
enable_password = {{ . | quote }};
{{- end }}
{{- with .Values.config.workerController.extraConfig }}
{{ . }}
{{- end }}
{{- end }}

{{/*
Redis config shared by Rspamd Redis modules.
*/}}
{{- define "rspamd.redisConfig" -}}
{{- $port := default 6379 .Values.redis.port -}}
servers = "{{ .Values.redis.host }}:{{ $port }}";
{{- with .Values.redis.db }}
db = {{ . | quote }};
{{- end }}
{{- with .Values.redis.username }}
username = {{ . | quote }};
{{- end }}
{{- with .Values.redis.password }}
password = {{ . | quote }};
{{- end }}
{{- with .Values.redis.timeout }}
timeout = {{ . | quote }};
{{- end }}
{{- end }}

{{/*
Redis history config uses the same backend connection details.
*/}}
{{- define "rspamd.historyRedisConfig" -}}
{{ include "rspamd.redisConfig" . }}
key_prefix = {{ .Values.config.historyRedis.keyPrefix | quote }};
nrows = {{ .Values.config.historyRedis.nrows }};
compress = {{ .Values.config.historyRedis.compress }};
subject_privacy = {{ .Values.config.historyRedis.subjectPrivacy }};
{{- with .Values.config.historyRedis.extraConfig }}
{{ . }}
{{- end }}
{{- end }}
