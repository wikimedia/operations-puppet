# == Class profile::statistics::web
#
class profile::statistics::web(
    $statistics_servers = hiera('statistics_servers'),
) {
    include ::standard
    include ::base::firewall

    include ::deployment::umask_wikidev

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics webserver nodes.
    include ::statistics::web

    # # include statistics web sites
    include ::statistics::sites::metrics
    include ::statistics::sites::stats
    include ::statistics::sites::analytics
    # Proxy to securely access Yarn (authentication via LDAP)
    include ::statistics::sites::yarn
    # Proxy to securely access Pivot (authentication via LDAP)
    include ::statistics::sites::pivot
    # Proxy to Hue (not authenticated via LDAP, delegated to app)
    include ::statistics::sites::hue

    ferm::service {'statistics-web':
        proto => 'tcp',
        port  => '80',
    }
}
