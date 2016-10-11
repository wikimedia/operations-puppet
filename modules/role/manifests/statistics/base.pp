# Base class for statistics roles
# FIXME: Do not use inheritance!
class role::statistics::base {
    include ::deployment::umask_wikidev

    # Manually set a list of statistics servers.
    $statistics_servers = hiera(
        'statistics_servers',
        [
            'stat1001.eqiad.wmnet',
            'stat1002.eqiad.wmnet',
            'stat1003.eqiad.wmnet',
            'analytics1027.eqiad.wmnet',
        ]
    )

    # we are attempting to stop using /a and to start using
    # /srv instead.  stat1002 still use
    # /a by default.  # stat1001 and stat1003 use /srv.
    $working_path = $::hostname ? {
        'stat1001' => '/srv',
        'stat1003' => '/srv',
        default    => '/a',
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
