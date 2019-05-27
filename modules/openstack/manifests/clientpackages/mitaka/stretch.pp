class openstack::clientpackages::mitaka::stretch(
) {
    require openstack::commonpackages::mitaka
    include openstack::designate::makedomain

    $py2packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
        'python-designateclient',
        'python-neutronclient',
    ]

    package{ $py2packages:
        ensure => 'present',
    }

    $otherpackages = [
        'ebtables',
        'python-netaddr',
    ]

    package { $otherpackages:
        ensure => 'present',
    }

    # in stretch, these packages are included in both our custom repo component
    # and in the stretch stable repo. Avoid conflicts with apt by avoiding
    # installing the version from our custom repo.
    # for dependency version reasons, we don't want those to be pulled from jessie-bpo
    # which means these no longer are mitaka when installed, which is not elegant
    # because this class is named mitaka, but hey..
    $avoid_packages = [
        'python3-keystoneauth1',
        'python3-keystoneclient',
        'python3-novaclient',
        'python3-glanceclient',
        'python3-openstackclient',
        'python3-designateclient',
        'python3-neutronclient',
        'python3-cffi-backend',
        'python3-stevedore',
        'python3-oslo.config',
        'python3-oslo.utils',
        'python3-osc-lib',
    ]

    $avoid_packages_list = join($avoid_packages, ' ')
    apt::pin { 'mitaka_stretch_nojessiebpo_clientpackages':
        package  => $avoid_packages_list,
        pin      => 'release c=openstack-mitaka-jessie',
        priority => '-1',
    }

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
