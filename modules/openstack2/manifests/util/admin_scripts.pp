# helper scripts for Labs openstack administration
class openstack2::util::admin_scripts(
    $version,
    ) {

    require_package('nova-common')
    # Installing this package ensures that we have all the UIDs that
    #  are used to store an instance volume.  That's important for
    #  when we rsync files via this host.
    require_package('libvirt-bin')

    file { '/usr/local/sbin/drain_queue':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => "puppet:///modules/openstack2/util/drain_queue",
    }

    # Script to cold-migrate instances between compute nodes
    file { '/root/cold-nova-migrate':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/cold-nova-migrate",
    }

    # Script to migrate (with suspension) instances between compute nodes
    file { '/root/live-migrate':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/live-migrate",
    }

    # Set up keystone services (example script)
    file { '/root/prod-example.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/prod.sh",
    }

    file { '/root/novastats':
        ensure => directory,
        owner  => 'root',
    }

    file { '/root/novastats/imagestats.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/imagestats.py",
        require => File['/root/novastats'],
    }

    file { '/root/novastats/diskspace.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/diskspace.py",
        require => File['/root/novastats'],
    }

    file { '/root/novastats/dnsleaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/dnsleaks.py",
    }

    file { '/root/novastats/proxyleaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/proxyleaks.py",
    }

    file { '/root/novastats/puppetleaks.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/puppetleaks.py",
    }

    file { '/root/novastats/flavorreport.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/flavorreport.py",
    }

    file { '/root/novastats/alltrusty.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/novastats/alltrusty.py",
    }

    file { '/usr/local/sbin/wikitech-grep':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/wikitech-grep.py",
    }

    # XXX: per deployment?
    file { '/root/.ssh/compute-hosts-key':
        content   => secret('ssh/nova/nova.key'),
        owner     => 'nova',
        group     => 'nova',
        mode      => '0600',
        require   => Package['nova-common'],
        show_diff => false,
    }

    # Script to rsync shutoff instances between compute nodes.
    #  This ignores most nova facilities so is a good last resort
    #  when nova is misbehaving.
    file { '/root/cold-migrate':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => "puppet:///modules/openstack2/${version}/admin_scripts/cold-migrate",
    }

    # Script and config to maintain DNS records for *.db.svc.eqiad.wmflabs
    # zones in Designate. These DNS zones are used by clients inside Cloud
    # VPS/Toolforge to connect to the Wiki Replica databases.
    file { '/etc/wikireplica_dns.yaml':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack2/util/wikireplica_dns.yaml',
    }

    file { '/usr/local/sbin/wikireplica_dns':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack2/util/wikireplica_dns.py',
    }
}
