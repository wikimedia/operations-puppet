# Class: role::toollabs::node::web
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
class role::toollabs::node::web {

    include ::toollabs::node::all
    include ::gridengine::submit_host

    # New style webservices!
    package { 'toollabs-webservice':
        ensure => latest,
    }

    # We have a tmp file problem to clean up
    package { 'tmpreaper':
        ensure => 'installed',
    }

    file { '/etc/tmpreaper.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/toollabs/web/tmpreaper.conf',
        require => Package['tmpreaper'],
    }

    class { '::gridengine::exec_host':
        config  => 'toollabs/gridengine/host-web.erb',
        require => File['/var/lib/gridengine'],
    }

    file { '/usr/local/lib/python2.7/dist-packages/portgrabber.py':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/toollabs/portgrabber.py',
        require => Package['python-yaml'],
    }

    file { '/usr/local/bin/portgrabber':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/portgrabber',
        require => File['/usr/local/lib/python2.7/dist-packages/portgrabber.py'],
    }

    file { '/usr/local/bin/portreleaser':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/portreleaser',
        require => File['/usr/local/lib/python2.7/dist-packages/portgrabber.py'],
    }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/jobkill',
    }

}
