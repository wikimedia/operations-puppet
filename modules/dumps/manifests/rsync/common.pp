class dumps::rsync::common {
    require_package('rsync')

    file { '/etc/rsyncd.d':
        ensure => 'directory',
    }
    file { '/etc/rsyncd.d/00-globalopts.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/rsync/rsyncd.conf.globalopts',
        notify => Exec['update-rsyncd.conf'],
    }
    exec { 'update-rsyncd.conf':
        command     => '/bin/cat /etc/rsyncd.d/*.conf > /etc/rsyncd.conf',
        refreshonly => true,
        require     => File['/etc/rsyncd.d'],
    }
    service { 'rsync':
        ensure    => running,
        enable    => true,
        subscribe => [ Exec['update-rsyncd.conf'] ],
    }
}
