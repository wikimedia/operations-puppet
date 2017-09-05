# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner (
    $queue_servers,
    $aggr_servers      = $queue_servers,
    $statsd_server     = undef,
    $port              = 9005,
    $running           = true,
    $runners_basic     = 0,
    $runners_html      = 0,
    $runners_upload    = 0,
    $runners_gwt       = 0,
    $runners_transcode = 0,
    $runners_transcode_prioritized = 0,
    $runners_translate = 0,
) {

    include ::passwords::redis

    # a rule for the `jobrunner` service:
    #
    #     ALL=(root) NOPASSWD: /usr/sbin/service jobrunner *
    #
    # will be added by scap::target as a result of defining `service_name`
    scap::target { 'jobrunner/jobrunner':
        deploy_user  => 'mwdeploy',
        manage_user  => false,
        service_name => 'jobrunner',
        sudo_rules   => [
            'ALL=(root) NOPASSWD: /usr/sbin/service jobchron *'
        ],
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

    $params = {
        ensure => $running ? {
            true    => 'running',
            default => 'stopped'
        },
        enable => $running,
    }

    # We declare the service, but override its status with
    # $service_ensure
    base::service_unit { 'jobrunner':
        systemd        => systemd_template('jobrunner'),
        upstart        => upstart_template('jobrunner'),
        service_params => $params,
        mask           => !$running,
    }

    base::service_unit { 'jobchron':
        systemd        => systemd_template('jobchron'),
        upstart        => upstart_template('jobchron'),
        service_params => $params,
        mask           => !$running,
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

    logrotate::conf { 'mediawiki_jobchron':
        ensure  => present,
        content => template('mediawiki/jobrunner/logrotate-jobchron.conf.erb'),
    }

    logrotate::conf { 'mediawiki_jobrunner':
        ensure  => present,
        content => template('mediawiki/jobrunner/logrotate.conf.erb'),
    }
}
