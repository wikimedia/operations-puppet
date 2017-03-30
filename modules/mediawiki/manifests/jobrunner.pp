# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner (
    $queue_servers,
    $aggr_servers      = $queue_servers,
    $runners_basic     = 0,
    $runners_html      = 0,
    $runners_upload    = 0,
    $runners_gwt       = 0,
    $runners_transcode = 0,
    $runners_transcode_prioritized = 0,
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

    $dispatcher = template('mediawiki/jobrunner/dispatcher.erb')

    file { '/etc/default/jobrunner':
        content => template('mediawiki/jobrunner/jobrunner.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }


    file { '/etc/jobrunner':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Service['jobrunner'],
    }

    file { '/etc/jobrunner/jobrunner.conf':
        content => template('mediawiki/jobrunner/jobrunner.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner', 'jobchron'],
    }

    $state = hiera('jobrunner_state', 'running')
    $params = {
        ensure => $state,
        enable => $state ? {
            'stopped' => false,
            default   => true,
        },
    }

    # We declare the service, but override its status with
    # $service_ensure
    base::service_unit { ['jobrunner', 'jobchron']:
        systemd        => true,
        upstart        => true,
        service_params => $params,
    }

    if $::initsystem == 'systemd' {
        rsyslog::conf { 'jobrunner':
            source   => 'puppet:///modules/mediawiki/jobrunner.rsyslog.conf',
            priority => 20,
            require  => [
              File['/etc/logrotate.d/mediawiki_jobrunner'],
              File['/etc/logrotate.d/mediawiki_jobchron'],
            ],
        }
    }

    file { '/etc/logrotate.d/mediawiki_jobchron':
        content => template('mediawiki/jobrunner/logrotate-jobchron.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/logrotate.d/mediawiki_jobrunner':
        content => template('mediawiki/jobrunner/logrotate.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    include ::apache::mod::proxy_fcgi

    class { '::apache::mpm':
        mpm => 'worker',
    }

    apache::conf { 'hhvm_jobrunner_port':
        priority => 1,
        content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>\n"),
    }

    apache::site{ 'hhvm_jobrunner':
        priority => 1,
        content  => template('mediawiki/jobrunner/site.conf.erb'),
    }

    # Hack for T122069: on servers running GWT jobs, restart HHVM
    # once it occupies more than 60% of the available memory
    if ($runners_gwt > 0) {
        cron { 'periodic_hhvm_restart':
            command => '/bin/ps -C hhvm -o pmem= | awk \'{sum+=$1} END { if (sum <= 50.0) exit 1  }\'  && /usr/sbin/service hhvm restart >/dev/null 2>/dev/null',
            minute  => fqdn_rand(59, 'periodic_hhvm_restart'),
        }
    } else {
        cron { 'periodic_hhvm_restart':
            ensure => absent,
        }
    }
}
