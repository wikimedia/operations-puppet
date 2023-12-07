{{/* SPDX-License-Identifier: Apache-2.0 */}}
{{- range gets "/request-ipblocks/abuse/blocked-nets" }}
  {{- $ipblock := json .Value }}
define {{ toUpper (base .Key) }} = {
  {{- range $cidr := $ipblock.cidrs }}
  {{ $cidr }} ,
  {{- end }}
}
{{- end }}
