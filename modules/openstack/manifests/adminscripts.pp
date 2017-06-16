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

    file { '/root/novastats/imagestats.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/imagestats.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/diskspace.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/diskspace.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/dnsleaks.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/dnsleaks.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/proxyleaks.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/proxyleaks.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/puppetleaks.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/puppetleaks.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/flavorreport.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/flavorreport.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/root/novastats/alltrusty.py':
        ensure => present,
        source => 'puppet:///modules/openstack/novastats/alltrusty.py',
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
