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

    file { '/usr/local/bin/git-sync-upstream':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/git-sync-upstream.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if ($private_only) {
        cron { 'rebase_labs_private_puppet':
            ensure  => present,
            user    => 'root',
            minute  => "*/${run_every_minutes}",
            command => "/usr/local/bin/git-sync-upstream --private-only ${prometheus_arg} >>/var/log/git-sync-upstream.log 2>&1",
            require => File['/usr/local/bin/git-sync-upstream'],
        }
    } else {
        cron { 'rebase_operations_puppet':
            ensure  => present,
            user    => 'root',
            minute  => "*/${run_every_minutes}",
            command => "/usr/local/bin/git-sync-upstream ${prometheus_arg} >>/var/log/git-sync-upstream.log 2>&1",
            require => File['/usr/local/bin/git-sync-upstream'],
        }
    }

    logrotate::conf { 'git-sync-upstream':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/git-sync-upstream.logrotate',
    }
}


