# SPDX-License-Identifier: Apache-2.0
# = Class: profile::query_service::graph_split
#
# This class opens the firewall to allow connecting to stat1006,
# and also provisions a cert for envoy via cfssl
class profile::query_service::graph_split {
    firewall::service {
        # T350106 temporary port to allow transfer of files from stat1006 to graph split hosts
        'graph_split_file_transfer':
          proto  => 'tcp',
          port   => 9876,
          srange => ['stat1006.eqiad.wmnet'],
    }

}
