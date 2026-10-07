{{- define "lostfound.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "lostfound.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "lostfound.labels" -}}
app.kubernetes.io/name: {{ include "lostfound.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* selector labels for one component: include "lostfound.selector" (list . "backend") */}}
{{- define "lostfound.selector" -}}
{{- $ctx := index . 0 -}}
app.kubernetes.io/name: {{ include "lostfound.name" $ctx }}
app.kubernetes.io/instance: {{ $ctx.Release.Name }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}

{{- define "lostfound.dbSecretName" -}}
{{- default (printf "%s-db" (include "lostfound.fullname" .)) .Values.database.existingSecret -}}
{{- end -}}

{{- define "lostfound.image" -}}
{{- $ctx := index . 0 -}}
{{- printf "%s/%s:%s" $ctx.Values.image.registry (index . 1) $ctx.Values.image.tag -}}
{{- end -}}

{{- define "lostfound.podSecurity" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{- define "lostfound.containerSecurity" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end -}}
