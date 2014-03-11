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

    mount { '/mnt/dumps':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        device  => 'labstore.svc.eqiad.wmnet:/dumps',
        options => 'rw,vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime,nofsc',
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

    cron { 'dumps_labs_rsync':
        ensure      => $ensure,
        user        => 'root',
        minute      => '50',
        hour        => '3',
        command     => '/usr/local/sbin/labs-rsync-cron.sh',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        require     => [File['/usr/local/bin/wmfdumpsmirror.py'],
                       File['/usr/local/sbin/labs-rsync-cron.sh'],
                       Mount['/mnt/dumps']],
    }
}

