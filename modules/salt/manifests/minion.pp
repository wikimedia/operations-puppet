class salt::minion(
    $salt_version='installed',
    $salt_master=undef,
    $salt_client_id=undef,
    $salt_cache_jobs=undef,
    $salt_module_dirs="[]",
    $salt_returner_dirs="[]",
    $salt_returner_dirs="[]",
    $salt_states_dirs="[]",
    $salt_render_dirs="[]",
    $salt_grains={},
    $salt_environment=undef,
    $salt_master_finger=undef,
    $salt_dns_check=undef,
){
    package { 'salt-minion':
        ensure => $salt_version,
    }

    service { 'salt-minion':
        ensure  => running,
        enable  => true,
        require => Package['salt-minion'],
    }

    file { '/etc/init/salt-minion.override':
        source  => 'puppet:///modules/salt/salt-minion.override',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['salt-minion'],
        require => Package['salt-minion'],
    }

    file { '/etc/salt/minion':
        content => template('salt/minion.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['salt-minion'],
        require => Package['salt-minion'],
    }

    file { '/usr/local/sbin/grain-ensure':
        source => 'puppet:///modules/salt/grain-ensure.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }
}
