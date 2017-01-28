# helper scripts for Labs openstack administration
class openstack::adminscripts(
    $novaconfig,
    $openstack_version = $::openstack::version,
    $nova_region = $::site,
    ) {

    $wikitech_nova_ldap_user_pass = $novaconfig['ldap_user_pass']
    $nova_controller_hostname = $novaconfig['controller_hostname']

    # Installing this package ensures that we have all the UIDs that
    #  are used to store an instance volume.  That's important for
    #  when we rsync files via this host.
    package { 'libvirt-bin':
        ensure => present,
    }

    # Script to cold-migrate instances between compute nodes
    file { '/root/cold-nova-migrate':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/cold-nova-migrate",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Script to migrate (with suspension) instances between compute nodes
    file { '/root/live-migrate':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/live-migrate",
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

    file { '/root/.ssh/compute-hosts-key':
        content => secret('ssh/nova/nova.key'),
        owner   => 'nova',
        group   => 'nova',
        mode    => '0600',
        require => Package['nova-common'],
    }

    # Script to rsync shutoff instances between compute nodes.
    #  This ignores most nova facilities so is a good last resort
    #  when nova is misbehaving.
    file { '/root/cold-migrate':
        ensure => present,
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/cold-migrate",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
