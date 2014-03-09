class dataset::rsync::common($ensure='present') {
    file { '/etc/rsyncd.d':
        ensure => directory,
    }
    file { '/etc/rsyncd.d/00-globalopts.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///dataset/rsync/rsyncd.conf.globalopts',
        notify  => Exec['update-rsyncd.conf'],
    }
    exec { 'update-rsyncd.conf':
        command     => '/bin/cat /etc/rsyncd.d/*.conf > /etc/rsyncd.conf',
        refreshonly => true,
        require     => File['/etc/rsyncd.d'],
    }

}
