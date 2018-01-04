# == Class profile::statistics::web
#
class profile::statistics::web(
    $statistics_servers = hiera('statistics_servers'),
    $geowiki_host       = hiera('profile::statistics::web::geowiki_host'),
) {

    include ::deployment::umask_wikidev

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics webserver nodes.
    class { '::statistics::web': }

    # # include statistics web sites
    class { '::statistics::sites::metrics': }
    class { '::statistics::sites::stats':
        geowiki_private_data_bare_host => $geowiki_host,
    }
    class { '::statistics::sites::analytics': }
    # Proxy to securely access Yarn (authentication via LDAP)
    class { '::statistics::sites::yarn': }
    # Proxy to securely access Pivot (authentication via LDAP)
    class { '::statistics::sites::pivot': }
    # Proxy to Hue (not authenticated via LDAP, delegated to app)
    class { '::statistics::sites::hue': }

    ferm::service {'statistics-web':
        proto => 'tcp',
        port  => '80',
    }
}
