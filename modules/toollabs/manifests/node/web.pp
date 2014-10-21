# Class: toollabs::node::web
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
class toollabs::node::web inherits toollabs {

    include gridengine::submit_host,
            toollabs::infrastructure

    file { '/usr/local/bin/portgrabber':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/portgrabber',
    }

    file { '/usr/local/sbin/portgranter':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/portgranter',
    }

    file { '/etc/init/portgranter.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/portgranter.conf',
    }
}

