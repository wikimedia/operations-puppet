# profile::toolforge::clush::master - configure clustershell master
#
# * $observer_pass - Password used to connect to OpenStack and retrieve
#                    list of instances

class profile::toolforge::clush::master(
    String $observer_pass = lookup('profile::openstack::main::observer_password'),
    ) {

    require ::profile::openstack::main::clientpackages

    class { '::clush::master':
        username => 'clushuser',
    }

    require_package('python3-yaml')

    file { '/usr/local/sbin/tools-clush-generator':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/tools-clush-generator',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/tools-clush-interpreter':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/tools-clush-interpreter',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/clush':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/clush',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'update_tools_clush':
        ensure  => present,
        command => "/usr/local/sbin/tools-clush-generator /etc/clustershell/tools.yaml --observer-pass ${observer_pass}",
        hour    => '*/1',
        user    => 'root',
    }

    $groups_config = {
        'Main' => {
            'default' => 'Tools',
        },
        'Tools' => {
            'map' => '/usr/local/sbin/tools-clush-interpreter --hostgroups /etc/clustershell/tools.yaml map $GROUP',
            'list' => '/usr/local/sbin/tools-clush-interpreter --hostgroups /etc/clustershell/tools.yaml list',
        },
    }

    file { '/etc/clustershell/groups.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ini($groups_config),
    }

    # Usage: `clush --hostfile /etc/clustershell/toolforge_canary_list.txt 'cmd'`
    file { '/etc/clustershell/toolforge_canary_list.txt':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/clush/toolforge_canary_list.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
