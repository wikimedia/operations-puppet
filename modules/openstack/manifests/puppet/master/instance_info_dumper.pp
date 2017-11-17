# Sets up a small python script that dumps all info about instances
# into a JSON file periodically
#
class openstack::puppet::master::instance_info_dumper(
    $puppetmaster,
    ) {

    require_package('python-requests')

    file { '/usr/local/sbin/instance-info-dumper':
        ensure => 'present',
        source => 'puppet:///modules/openstack/puppet/master/instance-info-dumper.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    $config = {
        'enc_host'    => $puppetmaster,
        'output_path' => '/srv/instance-info.yaml',
    }

    file { '/etc/instance-dumper.yaml':
        ensure  => 'present',
        content => ordered_yaml($config),
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
    }

    cron { 'dump-instances':
        ensure  => 'absent',
        user    => 'root',
        minute  => '*/15',
        command => '/usr/local/sbin/instance-info-dumper',
    }
}
