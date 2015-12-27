# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner (
    $queue_servers,
    $aggr_servers      = $queue_servers,
    $runners_basic     = 0,
    $runners_upload    = 0,
    $runners_gwt       = 0,
    $runners_restbase  = 0,
    $runners_transcode = 0,
    $runners_translate = 0,
    $statsd_server     = undef,
    $port              = 9005,
) {
    include ::passwords::redis

    package { 'jobrunner':
        ensure   => latest,
        provider => 'trebuchet',
        notify   => Service['jobrunner'],
    }

    $dispatcher = template("mediawiki/jobrunner/dispatchers/${lsbdistcodename}.erb")

    file { '/etc/default/jobrunner':
        content => template('mediawiki/jobrunner/jobrunner.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }

    file { '/etc/init/jobrunner.conf':
        source => 'puppet:///modules/mediawiki/jobrunner.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['jobrunner'],
    }

    file { '/etc/init/jobchron.conf':
        source => 'puppet:///modules/mediawiki/jobchron.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['jobchron'],
    }

    file { '/etc/jobrunner':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Service['jobrunner']
    }

    file { '/etc/jobrunner/jobrunner.conf':
        content => template('mediawiki/jobrunner/jobrunner.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }

    $service_ensure = hiera('jobrunner_state', 'running')
    service { 'jobrunner':
        ensure   => $service_ensure,
        provider => 'upstart',
    }

    service { 'jobchron':
        ensure   => $service_ensure,
        provider => 'upstart',
    }

    ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$INTERNAL',
    }

    file { '/etc/logrotate.d/mediawiki_jobrunner':
        source => 'puppet:///modules/mediawiki/logrotate.d_mediawiki_jobrunner',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    if os_version('ubuntu >= trusty') {
        include ::apache::mod::proxy_fcgi

        class { 'apache::mpm':
            mpm => 'worker',
        }

        apache::conf { 'hhvm_jobrunner_port':
            priority => 1,
            content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>\n"),
        }

        apache::site{ 'hhvm_jobrunner':
            priority => 1,
            content  => template('mediawiki/jobrunner/site.conf.erb')
        }

        # Hack for T122069: Once a day, check the uptime of HHVM. If HHVM has
        # been running for more than a day, restart it.
        cron { 'periodic_hhvm_restart':
            command => '/bin/ps -C hhvm -o etime= | /bin/grep -q - && /sbin/initctl restart hhvm',
            hour    => fqdn_rand(23, 'periodic_hhvm_restart'),
        }
    }

}
