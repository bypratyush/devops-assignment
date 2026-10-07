{{/*
Helpers shared by every template. `define` creates a named template, `include`
calls it and returns a string (so it can be piped into nindent/quote).
*/}}

{{/* Base name for all objects: the release name, e.g. notes-dev / notes-prod. */}}
{{- define "notes.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Selector labels - must never change for the life of a release. */}}
{{- define "notes.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Full label set: selector labels plus chart/version/environment metadata. */}}
{{- define "notes.labels" -}}
{{ include "notes.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.app.environment }}
{{- end }}

{{/* Full image reference. `required` stops rendering with a clear message. */}}
{{- define "notes.image" -}}
{{- printf "%s:%s" .Values.image.repository (required "image.tag must be set" .Values.image.tag) }}
{{- end }}
