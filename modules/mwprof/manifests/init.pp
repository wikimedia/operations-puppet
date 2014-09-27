# == Class: role::mwprof
#
# Sets up mwprof, a MediaWiki profiling log collector.
#
class mwprof(
    $carbon_host    = '127.0.0.1',
    $carbon_port    = 2003,
    $collector_port = 3811,
) {
    system::role { 'role::mwprof':
        description => 'MediaWiki profiler',
    }

    package { 'mwprof/mwprof':
        provider => 'trebuchet',
    }

    package { [ 'build-essential', 'libglib2.0-dev', 'glib-networking' ]: }

    group { 'mwprof':
        ensure => present,
    }

    user { 'mwprof':
        ensure     => present,
        gid        => 'mwprof',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file {
        '/etc/init/mwprof':
            ensure  => directory,
            recurse => true,
            purge   => true,
            force   => true,
            source  => 'puppet:///modules/mwprof/upstart';
        '/etc/init/mwprof/profiler-to-carbon.conf':
            content => template('mwprof/upstart/profiler-to-carbon.conf.erb');
        '/etc/init/mwprof/collector.conf':
            content => template('mwprof/upstart/collector.conf.erb');
    }

    file { '/sbin/mwprofctl':
        source  => 'puppet:///modules/mwprof/mwprofctl';
    }

    service { 'mwprof':
        ensure   => 'running',
        provider => 'base',
        restart  => '/sbin/mwprofctl restart',
        start    => '/sbin/mwprofctl start',
        status   => '/sbin/mwprofctl status',
        stop     => '/sbin/mwprofctl stop',
        require  => File['/sbin/mwprofctl'],
    }

    nrpe::monitor_service { 'mwprof':
        description  => 'MediaWiki profile collector',
        nrpe_command => '/sbin/mwprofctl check',
        require      => Service['mwprof'],
    }
}
