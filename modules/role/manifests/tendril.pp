# manifests/role/tendril.pp
# tendril: MariaDB Analytics (tendril.wikimedia.org)
# dbtree: Mariadb topology (dbtree.wikimedia.org)

class role::tendril {
    include ::profile::base::firewall
    include ::profile::standard

    interface::add_ip6_mapped { 'main': }

    system::role { 'tendril': description => 'tendril server' }

    include ::profile::tendril
    include ::profile::tendril::webserver

    # needed by ssl_ciphersuite() used in ::tendril
    class { '::sslcert::dhparam': }

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
