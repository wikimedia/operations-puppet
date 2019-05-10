# Class: profile::toolforge::node::web
#
# Common settings for all toollabs::node::web::* classes
#
# THIS SHOULD NOT BE INCLUDED DIRECTLY
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# filtertags: labs-project-tools
class profile::toolforge::grid::node::web (
    $etcdir = hiera('profile::toolforge::etcdir'),
){
    include profile::toolforge::grid::node::compute
    include profile::toolforge::grid::submit_host
    include profile::toolforge::k8s::client

    # We have a tmp file problem to clean up
    package { 'tmpreaper':
        ensure => 'installed',
    }

    file { '/etc/tmpreaper.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/toolforge/web/tmpreaper.conf',
        require => Package['tmpreaper'],
    }

    class { '::sonofgridengine::exec_host':
        config  => 'profile/toolforge/grid/host-web.erb',
        require => File['/var/lib/gridengine'],
    }

    file { '/usr/local/lib/python2.7/dist-packages/portgrabber.py':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/toolforge/portgrabber.py',
        require => Package['python-yaml'],
    }

    file { '/usr/local/bin/portgrabber':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/profile/toolforge/portgrabber_cli.py',
        require => File['/usr/local/lib/python2.7/dist-packages/portgrabber.py'],
    }

    file { '/usr/local/bin/portreleaser':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/profile/toolforge/portreleaser.py',
        require => File['/usr/local/lib/python2.7/dist-packages/portgrabber.py'],
    }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/jobkill',
    }

}
