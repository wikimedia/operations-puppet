# Base class for statistics roles
# FIXME: Do not use inheritance!
class role::statistics::base {
    include ::deployment::umask_wikidev

    $statistics_servers = hiera('statistics_servers')

    # We are attempting to stop using /a and to start using
    # /srv instead.  stat1002 still use
    # /a.  Everything else uses /srv.
    $working_path = $::hostname ? {
        'stat1002' => '/a',
        default    => '/srv',
    }

    class { '::statistics':
        servers      => $statistics_servers,
        working_path => $working_path,
    }

    # Allow rsyncd traffic from internal networks.
    # and stat* public IPs.
    ferm::service { 'rsync':
        proto  => 'tcp',
        port   => '873',
        srange => '$PRODUCTION_NETWORKS',
    }
}
