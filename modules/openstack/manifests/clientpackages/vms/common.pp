# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::common(
) {
    requires_realm('labs')
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

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/clientpackages/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
