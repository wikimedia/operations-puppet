{{/* SPDX-License-Identifier: Apache-2.0 */}}
{{- range gets "/request-ipblocks/abuse/*" }}
  {{- $ipblock := json .Value }}
@def ${{ toUpper (base .Key) }} = (
  {{- range $cidr := $ipblock.cidrs }}
  {{ $cidr }}
  {{- end }}
);
{{- end }}
