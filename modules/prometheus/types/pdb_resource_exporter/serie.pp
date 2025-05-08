# SPDX-License-Identifier: Apache-2.0
type Prometheus::Pdb_resource_exporter::Serie = Struct[{
  rtype  => Pattern[/^([A-Z][a-z0-9_]*)(::[A-Z][a-z0-9_]*)*$/],
  filter => String[1],
  uniq   => Boolean,
  name   => Pattern[/^[A-Za-z0-9]+([-_][A-Za-z0-9]+)*$/],
}]
