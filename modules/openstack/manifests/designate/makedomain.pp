class openstack::designate::makedomain
{
    # Functions to create or delete designate domains under .wmflabs.org
    file { '/usr/lib/python2.7/dist-packages/designatemakedomain.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/designate/designatemakedomain.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
