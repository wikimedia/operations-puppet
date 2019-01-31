# helper scripts for CloudVPS openstack administration
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
    file { '/usr/local/sbin/wmcs-cold-nova-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-cold-nova-migrate.py",
    }

    # Script to migrate from nova-network region to neutron region
    #  (hopefully this will only be needed transitionally)
    file { '/usr/local/sbin/wmcs-region-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-region-migrate.py",
    }
    file { '/usr/local/sbin/wmcs-region-migrate-security-groups':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-region-migrate-security-groups.py",
    }

    # Script to migrate (with suspension) instances between compute nodes
    file { '/usr/local/sbin/wmcs-live-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-live-migrate.py",
    }

    file { '/root/wmcs-nova-quota-sync':
        ensure => 'directory',
        owner  => 'root',
    }

    # Script to check and/or fix quotas.  With luck this won't be
    #  needed in Pike or later.
    file { '/usr/local/sbin/wmcs-nova-quota-sync':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-nova-quota-sync/wmcs-nova-quota-sync.py",
    }

    file { '/root/wmcs-nova-quota-sync/readme.md':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-nova-quota-sync/readme.md",
    }

    # Set up keystone services (example script)
    file { '/root/wmcs-prod-example.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-prod-example.sh",
    }

    file { '/usr/local/sbin/wmcs-novastats-imagestats':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-imagestats.py",
        require => File['/usr/local/sbin/wmcs-novastats'],
    }

    file { '/usr/local/sbin/wmcs-novastats-capacity':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-capacity.py",
        require => File['/usr/local/sbin/wmcs-novastats'],
    }

    file { '/usr/local/sbin/wmcs-novastats-dnsleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-dnsleaks.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-proxyleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-proxyleaks.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-puppetleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-puppetleaks.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-flavorreport':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-flavorreport.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-alltrusty':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/novastats/wmcs-novastats-alltrusty.py",
    }

    file { '/usr/local/sbin/wmcs-wikitech-grep':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-wikitech-grep.py",
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
    file { '/usr/local/sbin/wmcs-cold-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-cold-migrate.py",
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

    file { '/usr/local/sbin/wmcs-wikireplica-dns':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/util/wmcs-wikireplica-dns.py',
    }

    file { '/usr/local/sbin/wmcs-makedomain':
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-makedomain.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    # Script to list, add, and delete dynamicproxy entries. Also updates
    # Designate managed DNS entries for the proxied hostname.
    file { '/usr/local/sbin/wmcs-webproxy':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/util/wmcs-webproxy.py',
    }

    # Script to reassign VPS proxies to use a different proxy IP
    file { '/usr/local/sbin/wmcs-updateproxies':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/util/wmcs-updateproxies.py',
    }

    file { '/usr/local/sbin/wmcs-openstack':
        source => 'puppet:///modules/openstack/util/wmcs-openstack.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # rename cleanup
    $files = [
        '/root/cold-nova-migrate',
        '/root/region-migrate',
        '/root/region-migrate-security-groups',
        '/root/live-migrate',
        '/root/nova-quota-sync',
        '/root/nova-quota-sync/nova-quota-sync',
        '/root/nova-quota-sync/readme.md',
        '/root/prod-example.sh',
        '/root/novastats',
        '/root/novastats/imagestats.py',
        '/root/novastats/capacity.py',
        '/root/novastats/dnsleaks.py',
        '/root/novastats/proxyleaks.py',
        '/root/novastats/puppetleaks.py',
        '/root/novastats/flavorreport.py',
        '/root/novastats/alltrusty.py',
        '/usr/local/sbin/wikitech-grep',
        '/root/cold-migrate',
        '/usr/local/sbin/wikireplica_dns',
        '/root/makedomain',
        '/usr/local/sbin/webproxy',
        '/root/updateproxies',
        '/usr/local/sbin/openstack-cvps',
    ]

    file { $files:
        ensure => 'absent',
    }
}
