# = Class: role::toollabs::clush::master
#
# Clush master for toollabs. Allows orchestrating remote
# command execution on classes of toollabs instances. Hits
# the wikitech API to do discovery of all instances in
# toollabs. They are then classified by prefix using a list,
# maintained in modules/role/files/toollabs/clush/toollabs-clush-generator.
# This is refreshed every hour.
#
# For example, to run a command on all the kubernetes workers,
#  # clush -g k8s-worker -b 'uname -r'
#
# This will run it on all the k8s-workers, collect the output
# from them all (the -b option), dedupes them and displays them. You can specify fanout with -f - the default is 16.
#
# Right now the user has no sudo rights, but this will probably
# change!
class role::toollabs::clush::master {
    class { '::clush::master':
        username => 'clushuser',
    }

    require_package('python3-yaml')

    file { '/usr/local/sbin/tools-clush-generator':
        ensure => file,
        source => 'puppet:///modules/role/toollabs/clush/tools-clush-generator',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/tools-clush-interpreter':
        ensure => file,
        source => 'puppet:///modules/role/toollabs/clush/tools-clush-interpreter',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'update_tools_clush':
        ensure  => present,
        command => '/usr/local/sbin/tools-clush-generator /etc/clustershell/tools.yaml',
        hour    => '*/1',
        user    => 'root'
    }

    $groupsConfig = {
        'Main' => {
            'default' => 'Tools',
        },
        'Tools' => {
            'map' => '/usr/local/sbin/tools-clush-interpreter --hostgroups /etc/clustershell/tools.yaml map $GROUP',
            'list' => '/usr/local/sbin/tools-clush-interpreter --hostgroups /etc/clustershell/tools.yaml list',
        }
    }

    file { '/etc/clustershell/groups.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ini($groupsConfig),
    }
}
