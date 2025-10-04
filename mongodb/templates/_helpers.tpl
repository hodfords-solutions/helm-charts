{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}
