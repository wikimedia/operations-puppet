{{/* SPDX-License-Identifier: Apache-2.0 */}}
{{- $ipblock := json (getv "/request-ipblocks/abuse/blocked_nets") -}}
define BLOCKED_NETS_ipv4 = {
  {{- range $cidr := $ipblock.cidrs }}
  {{- if $cidr | strings.Contains "." }}
  {{ $cidr }},
  {{- end }}
  {{- end }}
}
define BLOCKED_NETS_ipv6 = {
  {{- range $cidr := $ipblock.cidrs }}
  {{- if $cidr | strings.Contains ":" }}
  {{ $cidr }},
  {{- end }}
  {{- end }}
}