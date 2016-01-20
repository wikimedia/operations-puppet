# gridengine/shadow_master.pp

class gridengine::shadow_master(
    $gridmaster = $grid_master,
    $sgeroot = '/var/lib/gridengine',
  ) {

    include ::gridengine
    package { 'gridengine-master':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    file { "${sgeroot}/default":
        ensure  => directory,
        require => [ File[$sgeroot], Package['gridengine-common'] ],
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '2775',
    }

    file { "${sgeroot}/default/common":
        ensure  => directory,
        require => File["${sgeroot}/default"],
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '2775',
    }

    file { '/etc/default/gridengine':
        ensure  => present,
        before  => Package['gridengine-common'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('gridengine/default-gridengine-shadow.erb'),
    }

    file { '/etc/init/gridengine-shadow.conf':
        ensure  => present,
        require => Package['gridengine-master'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/gridengine/gridengine-shadow.conf';
    }

    file { "${sgeroot}/default/common/shadow_masters":
        ensure  => present,
        require => File["${sgeroot}/default/common"],
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0555',
        content => "${::fqdn}\n",
    }

    service { 'gridengine-shadow':
        ensure  => running,
        require => File['/etc/init/gridengine-shadow.conf', "${sgeroot}/default/common/shadow_masters"],
    }
}
