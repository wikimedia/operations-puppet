# SPDX-License-Identifier: Apache-2.0
# Prometheus Elasticsearch Query Exporter.

class profile::prometheus::es_exporter (
    Optional[String]            $username            = lookup('profile::prometheus::es_exporter::username',            { default_value => undef } ),
    Optional[Sensitive[String]] $password            = lookup('profile::prometheus::es_exporter::password',            { default_value => undef } ),
    Optional[Stdlib::Unixpath]  $ca_cert             = lookup('profile::prometheus::es_exporter::ca_cert',             { default_value => undef } ),
    Optional[Stdlib::HTTPUrl]   $es_cluster_endpoint = lookup('profile::prometheus::es_exporter::es_cluster_endpoint', { default_value => 'http://localhost:9200' } ),
){
    class { 'prometheus::es_exporter':
        username            => $username,
        password            => $password,
        ca_cert             => $ca_cert,
        es_cluster_endpoint => $es_cluster_endpoint
    }
}
