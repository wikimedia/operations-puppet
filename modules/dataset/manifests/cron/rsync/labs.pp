class dataset::cron::rsync::labs($enable=true) {
    include role::mirror::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'dataset::cron::rsync::labs':
        ensure      => $ensure,
        description => 'rsyncer of dumps to labs fs'
    }

    file { '/mnt/dumps':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if ($enable) {
        mount { '/mnt/dumps':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            device  => 'labstore1003.eqiad.wmnet:/dumps',
            options => 'rw,vers=4,bg,soft,intr,timeo=14,sec=sys,proto=tcp,port=0,noatime,nofsc',
            require => File['/mnt/dumps'],
        }

        file { '/mnt/dumps/public':
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => Mount['/mnt/dumps'],
        }
    }

    file { '/usr/local/bin/wmfdumpsmirror.py':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/dataset/labs/wmfdumpsmirror.py',
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
            require     => File['/usr/local/bin/wmfdumpsmirror.py',
                                '/usr/local/sbin/labs-rsync-cron.sh',
                                '/mnt/dumps/public'],
        }
    }
    else {
        cron { 'dumps_labs_rsync':
            ensure      => absent,
        }
    }
}

