class openstack::designate::makedomain
{
    file { '/usr/lib/python3/dist-packages/designatemakedomain.py':
        ensure => 'present',
        source => 'puppet:///modules/openstack/designate/designatemakedomain.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}
