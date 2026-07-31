# SPDX-License-Identifier: Apache-2.0
#
# Metadata-only resource used to expose OpenSearch master-eligible nodes to
# PuppetDB consumers such as Cumin.
#
define opensearch::master_eligible (
    String $cluster_name,
    String $short_cluster_name,
) {
}
