# == Class: grafana::web::apache
#
# Configures a dedicated Apache vhost for Grafana.
#
# === Parameters
#
# [*server_name*]
#   Name of virtual server.
#
# [*listen*]
#   Interface / port to listen on (default: "*:80").
#
# [*elastic_backends*]
#   Array of URLs of ElasticSearch backends to use for storage.
#
# === Examples
#
#  class { '::grafana::web::apache':
#    server_name => 'grafana.wikimedia.org',
#  }
#
class grafana::web::apache(
    $server_name,
    $ensure           = present,
    $listen           = '*:80',
    $elastic_backends = undef,
) {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::proxy_balancer
    include ::apache::mod::proxy_http
    include ::apache::mod::lbmethod_byrequests
    include ::apache::mod::headers

    include ::passwords::ldap::production

    $auth_ldap = {
        name          => 'nda/ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-eqiad.wikimedia.org ldap-codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    apache::site { 'grafana':
        ensure  => $ensure,
        content => template('grafana/grafana.apache.erb'),
    }
}
