class torrus::discovery {
    require ::torrus::config
    require ::torrus::xmlconfig

    file { '/etc/torrus/discovery':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/etc/cron.daily/torrus-discovery':
        source => 'puppet:///modules/torrus/torrus-discovery',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    exec { 'torrus-discovery':
        require     => File['/etc/cron.daily/torrus-discovery'],
        command     => '/etc/cron.daily/torrus-discovery',
        timeout     => 1800,
        refreshonly => true,
        before      => Exec['torrus compile'],
    }
}

