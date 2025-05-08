# SPDX-License-Identifier: Apache-2.0
type Prometheus::Pdb_resource_exporter::Config = Struct[{
  series => Array[Prometheus::Pdb_resource_exporter::Serie],
}]
