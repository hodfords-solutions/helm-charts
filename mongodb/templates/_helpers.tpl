{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret holding the password of the user mongot syncs data with.
*/}}
{{- define "mongot.syncSourceSecretName" -}}
{{- .Values.mongot.syncSource.existingSecret | default (printf "%s-search-sync-source-password" .Values.name) }}
{{- end }}
