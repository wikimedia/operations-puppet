class openstack::neutron::linuxbridge_agent::rocky::buster(
) {
    require ::openstack::serverpackages::rocky::buster

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }

    # use iptables >= 1.8.5-3~bpo10+1 to avoid potential nft compat issues on buster
    apt::pin { 'apt_pin_iptables_linuxbridge_rocky_buster':
        pin      => 'release n=buster-backports',
        priority => 1002,
        package  => 'iptables',
    }

    # let puppet update the package to the latest, according to the pin above.
    # the upload to buster-bpo is usually made by Arturo anyway in upstream Debian
    # so if something breaks you can safely blame both him and FLOSS projects in general
    package { 'iptables' :
        ensure => latest,
    }
}
