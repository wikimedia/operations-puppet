# Utilities for querying openstack
class openstack::clientlib {
    include ::openstack::observerenv
    include ::openstack
    include ::openstack::repo

    $packages = [
        'python-novaclient',
        'python-glanceclient',
        'python-keystoneclient',
        'python-openstackclient',
    ]
    require_package($packages)

    # Wrapper python class to easily query openstack clients
    file { '/usr/lib/python2.7/dist-packages/mwopenstackclients.py':
        ensure => present,
        source => 'puppet:///modules/openstack/mwopenstackclients.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    if $::openstack::version != 'liberty' {
        # Python3 client packages are only available in Mitaka
        #  and later repos

        $python3packages = [
            'python3-keystoneclient',
            'python3-novaclient',
            'python3-glanceclient',
        ]
        require_package($python3packages)

        file { '/usr/lib/python3/dist-packages/mwopenstackclients.py':
            ensure => present,
            source => 'puppet:///modules/openstack/mwopenstackclients.py',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }
}
