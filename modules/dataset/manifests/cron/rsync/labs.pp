class dataset::cron::rsync::labs($enable=true) {
    include ::dataset::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file{ '/usr/local/sbin/labs-rsync-cron.sh':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/dataset/labs/labs-rsync-cron.sh',
    }

    if ($enable) {
        cron { 'dumps_labs_rsync':
            ensure      => $ensure,
            user        => 'root',
            minute      => '50',
            hour        => '3',
            command     => '/usr/local/sbin/labs-rsync-cron.sh',
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            require     => File['/usr/local/sbin/labs-rsync-cron.sh'],
        }
    }
    else {
        cron { 'dumps_labs_rsync':
            ensure      => absent,
        }
    }
}

