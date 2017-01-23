# == Class: role::labs::instance_info_dumper
#
# Sets up a small python script that dumps all info about instances
# into a JSON file periodically
class role::labs::instance_info_dumper {
    require_package('python-requests')

    $novaconfig = hiera_hash('novaconfig', {})

    file { '/usr/local/sbin/instance-info-dumper':
        ensure => present,
        source => 'puppet:///modules/role/labs/instance-info-dumper.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    $config = {
        'credentials' => {
            'username' => 'novaadmin',
            'api_key'  => $novaconfig['ldap_user_pass'],
            'auth_url' => "http://${novaconfig['controller_hostname']}:35357/v2.0",
        },
    'enc_host'    => hiera('labs_puppet_master'),
    'output_path' => '/srv/instance-info.yaml',
    }


    file { '/etc/instance-dumper.yaml':
        ensure  => present,
        content => ordered_yaml($config),
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
    }

    cron { 'dump-instances':
        ensure  => absent,
        user    => 'root',
        minute  => '*/15',
        command => '/usr/local/sbin/instance-info-dumper',
    }
}
