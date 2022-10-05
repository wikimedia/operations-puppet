# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::opensearch::datahubsearch
#
# Provisions OpenSearch backend node for a DataHubsearch cluster.
#
class profile::opensearch::datahubsearch {

    include profile::opensearch::server

    ferm::service {'opensearch-query':
        proto  => 'tcp',
        port   => '9200',
        srange => '$DOMAIN_NETWORKS',
    }
}
