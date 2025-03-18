# SPDX-License-Identifier: Apache-2.0

# Return all hosts that are configured in prometheus::instances
# Replaces the 'prometheus_all_nodes' variable, hence the 'hosts' vs 'nodes' naming
function prometheus::all_nodes () {
  $hosts = prometheus::instances().reduce([]) |$memo, $data| {
      $i_name = $data[0]
      $i_config = $data[1]

      if $i_config.has_key('hosts') {
        $memo + $i_config['hosts']
      } else {
        $memo
      }
  }
  $hosts.sort().unique()
}
