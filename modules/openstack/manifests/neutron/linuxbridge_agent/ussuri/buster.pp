class openstack::neutron::linuxbridge_agent::ussuri::buster(
) {
    require ::openstack::serverpackages::ussuri::buster

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }

    alternatives::select { 'iptables':
        path => '/usr/sbin/iptables-legacy',
    }
    alternatives::select { 'ip6tables':
        path => '/usr/sbin/ip6tables-legacy',
    }
    alternatives::select { 'ebtables':
        path    => '/usr/sbin/ebtables-legacy',
    }

    # Hack to fix pyroute2
    #
    # Upstream bug: https://bugs.launchpad.net/neutron/+bug/1899141
    #
    # This fix was backported to train but isn't present in our packages.
    # We'll need to check to see if it's present in U and V.
    #
    file { '/usr/lib/python3/dist-packages/neutron/agent/linux/ip_lib.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['neutron-linuxbridge-agent'],
        notify  => Service['neutron-linuxbridge-agent'],
        source  => 'puppet:///modules/openstack/ussuri/neutron/hacks/ip_lib.py';
    }
}
