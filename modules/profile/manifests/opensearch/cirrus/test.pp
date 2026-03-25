# SPDX-License-Identifier: Apache-2.0
class profile::opensearch::cirrus::test () {
    firewall::service {
        'opensearch-http-9200':
            proto    => 'tcp',
            port     => [9200],
            src_sets => ['ANALYTICS_NETWORKS'],
        ;
        'opensearch-inter-node-9300':
            proto  => 'tcp',
            port   => [9300],
            srange => wmflib::role::hosts('cirrus::test'),
        ;
    }
}
