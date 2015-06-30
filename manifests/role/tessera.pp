# == Class: role::tessera
#
# tessera is a dashboarding webapp for Graphite.
# It powers <https://tessera.wikimedia.org>.
#
class role::tessera {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::rewrite
    include ::apache::mod::uwsgi

    include ::passwords::tessera
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

    class { '::tessera':
        graphite_url => 'https://graphite.wikimedia.org',
        secret_key   => $passwords::tessera::secret_key,
    }

    apache::site { 'tessera.wikimedia.org':
        content => template('apache/sites/tessera.wikimedia.org.erb'),
        require => Class['::tessera'],
    }

    monitoring::service { 'tessera':
        description   => 'tessera.wikimedia.org',
        check_command => 'check_http_url!tessera.wikimedia.org!/',
    }
}
