{{/*
Expand the name of the chart.
*/}}
{{- define "clamav.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "clamav.fullname" -}}
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
{{- define "clamav.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clamav.labels" -}}
helm.sh/chart: {{ include "clamav.chart" . }}
{{ include "clamav.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clamav.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clamav.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "clamav.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "clamav.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate freshclam values.
*/}}
{{- define "clamav.validateFreshclam" -}}
{{- if and .Values.freshclam.httpProxyPassword .Values.freshclam.existingSecret -}}
{{- fail "freshclam.httpProxyPassword and freshclam.existingSecret cannot both be set" -}}
{{- end -}}
{{- if and .Values.freshclam.existingSecret (not .Values.freshclam.existingSecretPasswordKey) -}}
{{- fail "freshclam.existingSecretPasswordKey is required when freshclam.existingSecret is set" -}}
{{- end -}}
{{- if and (or .Values.freshclam.httpProxyPassword .Values.freshclam.existingSecret) (not .Values.freshclam.httpProxyServer) -}}
{{- fail "freshclam.httpProxyServer is required when a proxy password is set" -}}
{{- end -}}
{{- end }}

{{/*
freshclam config Secret name.
*/}}
{{- define "clamav.freshclamConfigSecretName" -}}
{{- printf "%s-freshclam-config" (include "clamav.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
True when the freshclam config holds a secret and must live in a Secret.
*/}}
{{- define "clamav.freshclamSecretEnabled" -}}
{{- if or .Values.freshclam.httpProxyPassword .Values.freshclam.existingSecret -}}true{{- end -}}
{{- end }}

{{/*
Name of the volume holding freshclam.conf.
*/}}
{{- define "clamav.freshclamConfigVolume" -}}
{{- if .Values.freshclam.existingSecret -}}
freshclam-config-rendered
{{- else if .Values.freshclam.httpProxyPassword -}}
freshclam-config
{{- else -}}
config
{{- end -}}
{{- end }}

{{/*
clamd.conf contents.
*/}}
{{- define "clamav.clamdConfig" -}}
LogTime yes
LogClean no
LogSyslog no
LogVerbose {{ ternary "yes" "no" .Values.clamd.logVerbose }}
Foreground yes
TCPAddr {{ .Values.clamd.tcpAddr }}
TCPSocket {{ .Values.clamd.tcpPort }}
DatabaseDirectory /var/lib/clamav
MaxFileSize {{ .Values.clamd.maxFileSize }}
MaxScanSize {{ .Values.clamd.maxScanSize }}
StreamMaxLength {{ .Values.clamd.streamMaxLength }}
MaxThreads {{ .Values.clamd.maxThreads }}
ReadTimeout {{ .Values.clamd.readTimeout }}
AlertEncryptedDoc {{ ternary "yes" "no" .Values.clamd.alertOnEncryptedDoc }}
AlertEncryptedArchive {{ ternary "yes" "no" .Values.clamd.alertOnEncryptedArchive }}
{{- with .Values.clamd.extraConfig }}
{{ . }}
{{- end }}
{{- end }}

{{/*
freshclam.conf contents. The proxy password is appended separately, either from a
Secret rendered by this chart or by the init container reading an existing Secret.
*/}}
{{- define "clamav.freshclamConfig" -}}
LogTime yes
LogSyslog no
LogVerbose no
Foreground yes
DatabaseDirectory /var/lib/clamav
Checks {{ .Values.freshclam.checks }}
{{- with .Values.freshclam.privateMirror }}
PrivateMirror {{ . }}
{{- end }}
DatabaseMirror {{ .Values.freshclam.databaseMirror }}
{{- with .Values.freshclam.httpProxyServer }}
HTTPProxyServer {{ . }}
{{- end }}
{{- with .Values.freshclam.httpProxyPort }}
HTTPProxyPort {{ . }}
{{- end }}
{{- with .Values.freshclam.httpProxyUsername }}
HTTPProxyUsername {{ . }}
{{- end }}
{{- with .Values.freshclam.httpProxyPassword }}
HTTPProxyPassword {{ . }}
{{- end }}
{{- with .Values.freshclam.extraConfig }}
{{ . }}
{{- end }}
{{- end }}

{{/*
clamav-milter.conf contents.
*/}}
{{- define "clamav.milterConfig" -}}
LogTime yes
LogSyslog no
LogVerbose {{ ternary "yes" "no" .Values.milter.logVerbose }}
Foreground yes
MilterSocket inet:{{ .Values.milter.tcpPort }}@{{ .Values.milter.tcpAddr }}
ClamdSocket {{ .Values.milter.clamdSocket }}
{{- with .Values.milter.extraConfig }}
{{ . }}
{{- end }}
{{- end }}
