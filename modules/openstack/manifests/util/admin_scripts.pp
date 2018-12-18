# helper scripts for Labs openstack administration
class openstack::util::admin_scripts(
    $version,
    ) {

    # Installing this package ensures that we have all the UIDs that
    #  are used to store an instance volume.  That's important for
    #  when we rsync files via this host.
    package{'libvirt-bin':
        ensure => 'present',
    }

    # Script to cold-migrate instances between compute nodes
    file { '/root/cold-nova-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/cold-nova-migrate",
    }

    # Script to migrate from nova-network region to neutron region
    #  (hopefully this will only be needed transitionally)
    file { '/root/region-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/region-migrate",
    }
    file { '/root/region-migrate-security-groups':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/region-migrate-security-groups",
    }

    # Script to migrate (with suspension) instances between compute nodes
    file { '/root/live-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/live-migrate",
    }

    file { '/root/nova-quota-sync':
        ensure => 'directory',
        owner  => 'root',
    }

    # Script to check and/or fix quotas.  With luck this won't be
    #  needed in Pike or later.
    file { '/root/nova-quota-sync/nova-quota-sync':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/nova-quota-sync/nova-quota-sync",
    }

    file { '/root/nova-quota-sync/readme.md':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/openstack/${version}/admin_scripts/nova-quota-sync/readme.md",
    }

    # Set up keystone services (example script)
    file { '/root/prod-example.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/prod.sh",
    }

    file { '/root/novastats':
        ensure => 'directory',
        owner  => 'root',
    }

    file { '/root/novastats/imagestats.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => "puppet:///modules/openstack/${version}/admin_scripts/novastats/imagestats.py",
        require => File['/root/novastats'],
    }

    file { '/root/novastats/capacity.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => "puppet:///modules/openstack/${version}/admin_scripts/novastats/capacity.py",
        require => File['/root/novastats'],
    }

    file { '/root/novastats/dnsleaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/dnsleaks.py",
    }

    file { '/root/novastats/proxyleaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/proxyleaks.py",
    }

    file { '/root/novastats/puppetleaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/puppetleaks.py",
    }

    file { '/root/novastats/flavorreport.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/flavorreport.py",
    }

    file { '/root/novastats/alltrusty.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/alltrusty.py",
    }

    file { '/usr/local/sbin/wikitech-grep':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wikitech-grep.py",
    }

    # XXX: per deployment?
    file { '/root/.ssh/compute-hosts-key':
        content   => secret('ssh/nova/nova.key'),
        mode      => '0600',
        show_diff => false,
    }

    # Script to rsync shutoff instances between compute nodes.
    #  This ignores most nova facilities so is a good last resort
    #  when nova is misbehaving.
    file { '/root/cold-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/cold-migrate",
    }

    # Script and config to maintain DNS records for *.db.svc.eqiad.wmflabs
    # zones in Designate. These DNS zones are used by clients inside Cloud
    # VPS/Toolforge to connect to the Wiki Replica databases.
    file { '/etc/wikireplica_dns.yaml':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/util/wikireplica_dns.yaml',
    }

    file { '/usr/local/sbin/wikireplica_dns':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/util/wikireplica_dns.py',
    }

    file { '/root/makedomain':
        source => "puppet:///modules/openstack/${version}/admin_scripts/makedomain",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }
}
