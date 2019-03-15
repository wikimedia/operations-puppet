# sonofgridengine/shadow_master.pp

class sonofgridengine::shadow_master(
    $gridmaster,
    $sgeroot = '/var/lib/gridengine',
) {

    include ::sonofgridengine
    package { 'gridengine-master':
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
        content => template('sonofgridengine/default-gridengine-shadow.erb'),
    }

    file_line { 'shadow_masters':
        ensure => present,
        after  => $gridmaster,
        line   => $::fqdn,
        path   => "${sgeroot}/default/common/shadow_masters",
    }

    file {'/usr/local/bin/grid-configurator':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/sonofgridengine/grid_configurator/grid_configurator.py',
    }

    # Installing the gridengine-master package will start the service
    service { 'gridengine-master':
        ensure => stopped,
        enable => false,
    }

    systemd::service { 'gridengine-shadow':
        ensure  => present,
        require => Package['gridengine-master'],
        content => systemd_template('shadow_master'),
    }

    file { '/etc/systemd/system/gridengine-shadow.service.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/systemd/system/gridengine-shadow.service.d/override.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "[Service]\nEnvironment=\"SGE_CHECK_INTERVAL=45\"\nEnvironment=\"SGE_GET_ACTIVE_INTERVAL=90\"\n",
        notify  => Exec['sonofgridengine-shadow_master-systemctl-override-daemon-reload'],
    }

    exec { 'sonofgridengine-shadow_master-systemctl-override-daemon-reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }
}
