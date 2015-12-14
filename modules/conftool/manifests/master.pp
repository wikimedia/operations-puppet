# == Class conftool::master
#
# Installs the conftool master scripts
#
class conftool::master($sync_dir = '/etc/conftool/data') {

    require conftool

    require ::puppetmaster::base_repo

    file { '/etc/conftool/data':
        ensure => link,
        target => "${::puppetmaster::base_repo::gitdir}/operations/puppet/conftool-data",
        force  => true,
        before => File['/usr/local/bin/conftool-merge'],
    }

    file { '/usr/local/bin/conftool-merge':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0500',
        content => template('conftool/conftool-merge.erb')
    }

    if $::conftool::auth {
        # Install a conftool role and a user too
        etcd_role { 'conftool':
            ensure => present,
            acls   => {
                '/conftool/*' => 'RW'
            }
        }

        if $::conftool::password != undef {
            etcd_user { 'conftool':
                ensure   => present,
                password => $::conftool::password,
                roles    => ['conftool', 'guest'],
            }
        }
    }
}
