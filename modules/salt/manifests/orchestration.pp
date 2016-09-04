class salt::orchestration() {
    package { [
        'python-dnspython',
        'python-phabricator',
    ]:
            ensure => present;
    }

    file { '/usr/local/bin/wmf-auto-reimage':
        ensure => present,
        source => 'puppet:///modules/salt/wmf-auto-reimage.py',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    class { '::phabricator::bot':
        username => 'ops-monitoring-bot',
        token    => $passwords::phabricator::ops_monitoring_bot_token,
        owner    => 'root',
        group    => 'root',
    }
}
