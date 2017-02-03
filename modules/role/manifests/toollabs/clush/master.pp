# = Class: role::toollabs::clush::master
#
# Clush master for toollabs. Allows orchestrating remote
# command execution on classes of toollabs instances. Hits
# the wikitech API to do discovery of all instances in
# toollabs. They are then classified by prefix using a list,
# maintained in modules/role/files/toollabs/clush/toollabs-clush-generator.
# This is refreshed every hour.
#
# You'll have to be a member of tools.admin to run this. All accesses
# are logged to /var/log/clush.log.
#
# For example, to run a command on all the kubernetes workers,
#  $ clush -g k8s-worker -b 'uname -r'
#
# This will run it on all the k8s-workers, collect the output
# from them all (the -b option), dedupes them and displays them. You can specify fanout with -f - the default is 16.
#
# filtertags: labs-project-toolsbeta labs-project-tools
class role::toollabs::clush::master {
    include ::toollabs::infrastructure

    class { '::clush::master':
        username => 'clushuser',
    }

    require_package('python3-yaml')

    include ::openstack::clientlib
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

    # override /usr/bin/clush with this! Just does additional logging
    # and makes sure users aren't runnning it as root. It logs to
    # /var/log/clush.log. Only people in tools.admin can run this!
    file { '/usr/local/bin/clush':
        ensure => file,
        source => 'puppet:///modules/role/toollabs/clush/clush',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $novaconfig = hiera_hash('novaconfig', {})
    $observer_pass = $novaconfig['observer_password']
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
}
