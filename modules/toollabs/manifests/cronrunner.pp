class toollabs::cronrunner {
    include gridengine::submit_host,
            toollabs::hba,
            toollabs

    # We need to include exec environment here since the current
    # version of jsub checks the local environment to find the full
    # path to things before submitting them to the grid. This assumes
    # that jsub is always run in an environment identical to the exec
    # nodes. This is kind of terrible, so we need to fix that eventually.
    # Until then...
    include toollabs::exec_environ

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
    }

    motd::script { 'submithost-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-submithost-banner",
    }

    # ;_; :'()
    file { '/usr/local/bin/jlocal':
        ensure => present,
        source => 'puppet:///modules/toollabs/jlocal',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Backup crontabs! See https://phabricator.wikimedia.org/T95798
    file { '/data/project/.system/crontabs':
        ensure => directory,
        owner  => 'root',
        group  => "${::labsproject}.admin",
        mode   => '0770',
    }
    file { "/data/project/.system/crontabs/${::fqdn}":
        ensure  => directory,
        source  => '/var/spool/cron/crontabs',
        owner   => 'root',
        group   => "${::labsproject}.admin",
        mode    => '0440',
        recurse => true,
    }
}
