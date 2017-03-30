# == Class profile::conftool::master
#
# Class to configure a conftool master, that will be able to
# sync data from yaml files in $sync_dir
#
# [*parameters*]
#   sync_dir The directory to sync from in conftool-merge
#
class profile::conftool::master(
    $sync_dir = hiera('profile::conftool::master::sync_dir'),
) {
    # All the configuration we have for the client is needed by the master
    require ::profile::conftool::client

    # We also need to know where the puppet repo is. We cannot require a profile
    # here because the puppet classes are not well structured. TODO: fix this
    # and transform the git dir into a parameter
    require ::puppetmaster::base_repo

    file { '/etc/conftool/data':
        ensure => link,
        target => "${::puppetmaster::base_repo::gitdir}/operations/puppet/conftool-data",
        force  => true,
        before => File['/usr/local/bin/conftool-merge'],
    }

    file { '/usr/local/bin/conftool-merge':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('conftool/conftool-merge.erb'),
    }

    # Note: we do not include etcd's own auth defines as we are discouraging using it
    # in favour of proxying via nginx. This might change when/if we switch to etcd 3
}
