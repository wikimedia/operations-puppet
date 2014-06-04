# == Class: webperf
#
# This Puppet module provisions a set of client-side performance
# monitoring scripts for Wikimedia sites.
#
class webperf {

    generic::systemuser { 'webperf':
        name          => 'webperf',
        home          => '/nonexistent',
        managehome    => false,
        shell         => '/bin/false',
        default_group => 'webperf',
    }

    file { '/srv/webperf':
        ensure => directory,
    }
}
