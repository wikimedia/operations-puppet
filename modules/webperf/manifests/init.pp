# == Class: webperf
#
# This Puppet module provisions a set of client-side performance
# monitoring scripts for Wikimedia sites.
#
class webperf {
    group { 'webperf':
        ensure => present,
    }

    user { 'webperf':
        ensure     => present,
        gid        => 'webperf',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/srv/webperf':
        ensure => directory,
    }

    nrpe::monitor_service { 'statsv':
        description  => 'statsv process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C python -a statsv',
    }
}
