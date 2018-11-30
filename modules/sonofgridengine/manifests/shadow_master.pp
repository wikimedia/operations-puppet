# sonofgridengine/shadow_master.pp

class sonofgridengine::shadow_master(
    $gridmaster,
    $sgeroot = '/var/lib/gridengine',
) {

    include ::sonofgridengine
    package { ['gridengine-master', 'gridengine-client']:
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    file { "${sgeroot}/default":
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '2775',
        require => [ File[$sgeroot], Package['gridengine-common'] ],
    }

    file { "${sgeroot}/default/common":
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '2775',
        require => File["${sgeroot}/default"],
    }

    file { '/etc/default/gridengine':
        ensure  => present,
        before  => Package['gridengine-common'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('gridengine/default-gridengine-shadow.erb'),
    }

    file { "${sgeroot}/default/common/shadow_masters":
        ensure  => present,
        require => File["${sgeroot}/default/common"],
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0555',
        content => "${::fqdn}\n",
    }

    file {'/usr/local/bin/grid-configurator':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/sonofgridengine/grid_configurator/grid_configurator.py',
    }

    file { '/var/run/gridengine':
        ensure => directory,
        force  => true,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0775',
    }

    systemd::service { 'gridengine-shadow':
        ensure  => present,
        require => [ Package['gridengine-master'],File["${sgeroot}/default/common/shadow_masters"] ],
        content => systemd_template('shadow_master'),
    }
}
