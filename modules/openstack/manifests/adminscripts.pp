class openstack::adminscripts(
    $novaconfig,
    $openstack_version = $::openstack::version,
    ) {
    include passwords::openstack::nova
    $wikitech_nova_ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass
    $nova_controller_hostname = $novaconfig['controller_hostname']
    $nova_region = $::site

    # Handy script to set up environment for commandline nova magic
    file { '/root/novaenv.sh':
        content => template('openstack/novaenv.sh.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    # Script to cold-migrate instances between compute nodes
    file { '/root/cold-migrate':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/cold-migrate",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Script to migrate instance from one dc to another
    # (specifically, pmtpa to eqiad)
    file { '/root/dc-migrate':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/dc-migrate",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Log analysis tool
    file { '/root/logstat.py':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/logstat.py",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Set up keystone services (example script)
    file { '/root/prod-example.sh':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/prod.sh",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats':
        ensure => directory,
        owner  => 'root',
    }

    file { '/root/novastats/novastats.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/novastats.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/saltstats':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/saltstats',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/imagestats':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/imagestats',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
