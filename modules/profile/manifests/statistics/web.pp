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
    class { '::statistics::sites::stats': }
    class { '::statistics::sites::analytics': }

    ferm::service {'statistics-web':
        proto => 'tcp',
        port  => '80',
    }
}
