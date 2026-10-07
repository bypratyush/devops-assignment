{{/* Resource name: just the release name, trimmed to the 63-char DNS limit. */}}
{{- define "rollback-web.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Labels that never change between revisions - safe to use as a selector. */}}
{{- define "rollback-web.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Full label set for metadata. */}}
{{- define "rollback-web.labels" -}}
{{ include "rollback-web.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
