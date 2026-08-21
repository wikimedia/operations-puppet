# SPDX-License-Identifier: Apache-2.0
# Prometheus Elasticsearch Query Exporter.

class profile::prometheus::es_exporter (
    Optional[String]            $username              = lookup('profile::prometheus::es_exporter::username',              { default_value => undef } ),
    Optional[Sensitive[String]] $password              = lookup('profile::prometheus::es_exporter::password',              { default_value => undef } ),
    Optional[String]            $cluster_name          = lookup('profile::prometheus::es_exporter::cluster_name',          { default_value => undef } ),
    Optional[String]            $pki_intermediate_name = lookup('profile::prometheus::es_exporter::pki_intermediate_name', { default_value => undef } ),
    Optional[Stdlib::Host]      $hostname_override     = lookup('profile::prometheus::es_exporter::hostname_override',     { default_value => undef } ),
    Stdlib::Port                $es_cluster_port       = lookup('profile::prometheus::es_exporter::es_cluster_port',       { default_value => 9200 } ),
){
    $_certificate_fqdn_replaced = inline_template('<%= @facts["networking"]["fqdn"].gsub(".", "_") %>')
    $tls_ca_cert = $username ? {
        undef   => undef,
        default => "/etc/opensearch/${cluster_name}/ssl/${pki_intermediate_name}__${_certificate_fqdn_replaced}.chain.pem"
    }
    $scheme = $pki_intermediate_name ? {
        undef   => 'http',
        default => 'https',
    }
    $es_cluster_fqdn = $hostname_override ? {
        undef   => $facts['networking']['fqdn'],
        default => $hostname_override
    }
    class { 'prometheus::es_exporter':
        username            => $username,
        password            => $password,
        ca_cert             => $tls_ca_cert,
        es_cluster_endpoint => "${scheme}://${es_cluster_fqdn}:${es_cluster_port}"
    }
}
