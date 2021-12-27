# == Class: puppetmaster::gitsync
#
# Sync local operations/puppet.git checkout with upstream.
class puppetmaster::gitsync(
    Integer $run_every_minutes = 10,
    Boolean $private_only = false,
    Optional[Stdlib::Unixpath] $prometheus_file = '/var/lib/prometheus/node.d/puppet-gitsync.prom',
){

    ensure_packages([
        'python3-git',
        'python3-prometheus-client',
        'python3-requests',
    ])

    if $prometheus_file {
        $prometheus_arg = " --prometheus-file ${prometheus_file}"
    } else {
        $prometheus_arg = ''
    }

    $private_arg = $private_only.bool2str(' --private-only', '')

    file { '/usr/local/bin/git-sync-upstream':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/git-sync-upstream.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::timer::job { 'puppet-git-sync-upstream':
        ensure      => 'present',
        user        => 'root',
        description => 'Update local Puppet repository copies',
        command     => "/usr/local/bin/git-sync-upstream ${prometheus_arg} ${private_arg}",
        interval    => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => "${run_every_minutes}m",
        },
    }
}


