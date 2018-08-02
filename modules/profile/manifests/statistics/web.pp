# == Class profile::statistics::web
#
class profile::statistics::web(
    $statistics_servers = hiera('statistics_servers'),
) {

    include ::deployment::umask_wikidev

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics webserver nodes.
    class { '::statistics::web': }

    # # include statistics web sites
    class { '::statistics::sites::metrics': }
    class { '::statistics::sites::stats': }
    class { '::statistics::sites::analytics': }
    # Proxy to securely access Yarn (authentication via LDAP)
    class { '::statistics::sites::yarn': }
    # Proxy to securely access Turnilo (authentication via LDAP)
    # Redirects also pivot.wikimedia.org's requests to turnilo
    class { '::statistics::sites::turnilo': }
    # Proxy to Hue (not authenticated via LDAP, delegated to app)
    class { '::statistics::sites::hue': }

    ferm::service {'statistics-web':
        proto => 'tcp',
        port  => '80',
    }
}
