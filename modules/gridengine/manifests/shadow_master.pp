# gridengine.pp


class gridengine::shadow_master(
    $gridmaster = $grid_master,
    $sgeroot = '/var/lib/gridengine',
  ) {
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { 'gridengine-master':
        ensure => latest,
        require => Package['gridengine-common'],
    }

    file { "$sgeroot/default":
        require => [ File[$sgeroot], Package['gridengine-common'] ],
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '02775',
    }

    file { "$sgeroot/default/common":
        require => File["$sgeroot/default"],
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '02775',
    }

    file { '/etc/default/gridengine':
        before  => Package['gridengine-common'],
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('gridengine/default-gridengine-shadow.erb'),
    }

    file { '/etc/init/gridengine-shadow.conf':
        require => Package['gridengine-master'],
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/gridengine/gridengine-shadow.conf';
    }

    file { "$sgeroot/default/common/shadow_masters":
        require => File["$sgeroot/default/common"],
        ensure  => present,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0555',
        content => $fqdn,
    }

    service { 'gridengine-shadow':
        require => File['/etc/init/gridengine-shadow.conf', "$sgeroot/default/common/shadow_masters"],
        ensure  => running,
    }
}

