# helper scripts for CloudVPS openstack administration
class openstack::util::admin_scripts(
    $version,
    ) {

    # Installing this package ensures that we have all the UIDs that
    #  are used to store an instance volume.  That's important for
    #  when we rsync files via this host.
    $libvirt = $facts['lsbdistcodename'] ? {
        'stretch' => 'libvirt-clients',
        'buster' => 'libvirt-clients',
        'bullseye' => 'libvirt-clients',
    }

    package{ $libvirt :
        ensure => 'present',
    }

    # We need a mysql client in order to run wmcs-cold-migrate and wmcs-ceph-migrate;
    #  they modify the VM host directly in the db
    package{ 'mariadb-client':
        ensure => 'present',
    }

    package{ 'python3-pytest':
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

    # Scripts to backup up/restore cinder volumes
    file { '/usr/local/sbin/wmcs-cinder-volume-backup':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-cinder-volume-backup.py",
    }
    file { '/usr/local/sbin/wmcs-cinder-backup-manager':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-cinder-backup-manager.py",
    }

    # Script to generate a new base image from an upstream image
    file { '/usr/local/sbin/wmcs-image-create':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-image-create.py",
    }

    # Script to suspend the whole cloud
    file { '/usr/local/sbin/wmcs-pause-cloud':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-pause-cloud.py",
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

    # Set up keystone services (example script)
    file { '/root/wmcs-prod-example.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-prod-example.sh",
    }

    file { '/usr/local/sbin/wmcs-novastats-imagestats':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-imagestats.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-capacity':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-capacity.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-dnsleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-dnsleaks.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-cephleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-cephleaks.py",
    }

    file { '/usr/local/sbin/wmcs-puppetcertleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-puppetcertleaks.py",
    }


    file { '/usr/local/sbin/wmcs-novastats-proxyleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-proxyleaks.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-puppetleaks':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-puppetleaks.py",
    }

    file { '/usr/local/sbin/wmcs-novastats-flavorreport':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-novastats/wmcs-novastats-flavorreport.py",
    }

    file { '/usr/local/sbin/wmcs-wikitech-grep':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-wikitech-grep.py",
    }

    file { '/usr/local/sbin/wmcs-securitygroup-backfill':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-securitygroup-backfill.py",
    }

    # XXX: per deployment?
    file { '/root/.ssh':
        ensure => directory,
    }

    file { '/root/.ssh/compute-hosts-key':
        content   => secret('ssh/nova/nova.key'),
        mode      => '0600',
        show_diff => false,
        require   => File['/root/.ssh'],
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

    # Script to copy a host from a non-ceph cloudvirt
    #  to a ceph-enabled cloudvirt
    file { '/usr/local/sbin/wmcs-ceph-migrate':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-ceph-migrate.py",
    }

    # Script to drain a ceph-enabled cloudvirt via live migration
    file { '/usr/local/sbin/wmcs-drain-hypervisor':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-drain-hypervisor.py",
    }

    # Script to list all flavors and number of VMs using the flavor
    file { '/usr/local/sbin/wmcs-flavorusage':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-flavorusage.py",
    }

    # Script to dump wikitext for the annual purge wikitech page
    file { '/usr/local/sbin/wmcs-annual-purge':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-annual-purge.py",
    }

    # Script to list all images and number of VMs using the flavor
    file { '/usr/local/sbin/wmcs-imageusage':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-imageusage.py",
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

    file { '/usr/local/sbin/wmcs-instance-fqdns':
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-instance-fqdns.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    file { '/usr/local/sbin/wmcs-makedomain':
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-makedomain.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    file { '/usr/local/sbin/wmcs-populate-domains':
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-populate-domains.py",
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

    # Script to update virtual machine extra specs (flavor options)
    file { '/usr/local/sbin/wmcs-vm-extra-specs':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-vm-extra-specs.py",
    }

    # Verify policies are working as we hope. This file must have the .py extension
    #  or else pytests won't believe in it.
    file { '/usr/local/sbin/wmcs-policy-tests.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-policy-tests.py",
    }

    # Script to wipe out old VMs in a project
    file { '/usr/local/sbin/wmcs-instancepurge':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-instancepurge.py",
    }

    # Script to interact with the puppet enc api
    file { '/usr/local/sbin/wmcs-enc-cli':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/util/wmcs-enc-cli.py',
    }
}
