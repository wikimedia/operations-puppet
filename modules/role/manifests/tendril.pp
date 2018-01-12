# manifests/role/tendril.pp
# tendril: MariaDB Analytics

class role::tendril {
    include ::base::firewall
    include ::standard

    system::role { 'tendril': description => 'tendril server' }

    # T62183 | TODO/FIXME: remove hiera condition once T150771 is resolved
    # aware that there should not be a permanent hiera lookup here
    # should be converted to role/profile anyways (like everything else)
    # if still needed move hiera lookup to parameters
    if hiera('do_acme', true) {
        monitoring::service { 'https-tendril':
            description   => 'HTTPS-tendril',
            check_command => 'check_ssl_http_letsencrypt!tendril.wikimedia.org',
        }
    }

    class { '::tendril':
        site_name    => 'tendril.wikimedia.org',
        docroot      => '/srv/tendril/web',
        ldap_binddn  => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_authurl => 'ldaps://ldap-labs.eqiad.wikimedia.org ldap-labs.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        ldap_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
        auth_name    => 'WMF Labs (use wiki login name not shell) - nda/ops/wmf',
    }

    # MariaDB (Tendril) maintenance
    include ::profile::mariadb::maintenance

    # Make tendril active-passive cross-datacenter until a local db backend is
    # available on codfw to avoid cross-dc queries or TLS is used to connect
    if hiera('do_acme', true) {
        ferm::service { 'tendril-http-https':
            proto => 'tcp',
            port  => '(http https)',
        }
    }
}
