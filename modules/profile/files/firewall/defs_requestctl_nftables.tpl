{{/* SPDX-License-Identifier: Apache-2.0 */}}
{{- $ipblock := json (getv "/request-ipblocks/abuse/blocked_nets") -}}
define BLOCKED_NETS = {
  {{- range $cidr := $ipblock.cidrs }}
  {{ $cidr }},
  {{- end }}
}
