# manifests/role/tendril.pp
# tendril: MariaDB Analytics (tendril.wikimedia.org)
# dbtree: Mariadb topology (dbtree.wikimedia.org)

class role::tendril {
    include ::profile::base::firewall
    include ::profile::standard

    interface::add_ip6_mapped { 'main': }

    system::role { 'tendril': description => 'tendril server' }

    include ::profile::tendril::webserver

    # needed by ssl_ciphersuite() used in ::tendril
    class { '::sslcert::dhparam': }
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
        auth_name    => 'Developer account (use wiki login name not shell) - nda/ops/wmf',
    }

    # Make tendril active-passive cross-datacenter until a local db backend is
    # available on codfw to avoid cross-dc queries or TLS is used to connect
    if hiera('do_acme', true) {
        ferm::service { 'tendril-http-https':
            proto => 'tcp',
            port  => '(http https)',
        }
    }

    class { '::dbtree': }

    # Run cron jobs needed for maintenance (but only on a single host/dc)
    include ::profile::tendril::maintenance
}
