# == Class: ocg
#
# Node service for the MediaWiki Collection extension providing article
# rendering.
#
# Collections, or books, or individual articles are submitted
# to the service as jobs which are stored in redis. Any node may accept
# a job on behalf of the cluster (providing all nodes share a redis
# instance.) Similarly, any node is then able to pick up the job when it
# is free to work.
#

class ocg (
    $host_name = $::hostname,
    $service_port = 8000,
    $redis_host = 'localhost',
    $redis_port = 6379,
    $redis_password = '',
    $statsd_host = 'localhost',
    $statsd_port = 8125,
    $statsd_is_txstatsd = 0,
    $graylog_host = 'localhost',
    $graylog_port = 12201,
    $temp_dir = '/srv/deployment/ocg/tmp',
    $output_dir = '/srv/deployment/ocg/output',
    $postmortem_dir = '/srv/deployment/ocg/postmortem'
) {
    deployment::target { 'ocg': }

    group { 'ocg':
        ensure => present,
    }

    user { 'ocg':
        ensure     => present,
        gid        => 'ocg',
        shell      => '/bin/false',
        home       => '/srv/deployment/ocg',
        managehome => false,
        system     => true,
    }

    if ( $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '14.04') >= 0 ) {
        # Although we need NodeJS on the server, only ubuntu 14.04 currently
        # comes with it. On labs or 12.04 boxes it has to be installed by hand :(
        package { 'nodejs':
            ensure => present,
            notify => Service['ocg'],
        }
    }

    # NOTE: If you change $nodebin you MUST also change the AppArmor profile
    #       creation below.
    $nodebin = '/usr/bin/nodejs-ocg'
    if ( $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 ) {
        # On ubuntu versions greater than 12.04 node is known as nodejs
        # We use the hardlink for a discrete AppArmor profile
        apparmor::hardlink { $nodebin:
            target => '/usr/bin/nodejs',
        }
    } else {
        apparmor::hardlink { $nodebin:
            target => '/usr/bin/node',
        }
    }

    package {
        [
            'texlive-xetex',
            'texlive-latex-recommended',
            'texlive-latex-extra',
            'texlive-generic-extra',
            'texlive-fonts-recommended',
            'texlive-fonts-extra',
            'texlive-lang-all',
            'fonts-hosny-amiri',
            'ttf-devanagari-fonts',
            'fonts-farsiweb',
            'fonts-nafees',
            'ttf-indic-fonts-core',
            'ttf-malayalam-fonts',
            'fonts-arphic-uming',
            'fonts-arphic-ukai',
            'fonts-droid',
            'fonts-baekmuk',
            'latex-xcolor',
            'lmodern',
            'imagemagick',
            'libjpeg-progs',
            'librsvg2-bin',
            'unzip',
            'zip',
        ]:
        ensure => present,
        before => Service['ocg']
    }

    service { 'ocg':
        ensure     => running,
        provider   => upstart,
        hasstatus  => false,
        hasrestart => false,
        require    => File['/etc/init/ocg.conf'],
    }

    file { '/etc/ocg':
        ensure => directory,
    }

    file { '/etc/ocg/mw-ocg-service.js':
        ensure  => present,
        owner   => 'ocg',
        group   => 'ocg',
        mode    => '0440',
        content => template('ocg/mw-ocg-service.js.erb'),
        notify  => Service['ocg'],
    }

    file { '/etc/init/ocg.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ocg/ocg.upstart.conf.erb'),
        require => User['ocg'],
        notify  => Service['ocg'],
    }
        
    # Change this if you change the value of $nodebin
    file { '/etc/apparmor.d/usr.bin.nodejs-pdf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('ocg/usr.bin.nodejs.apparmor.erb'),
        notify  => Service['apparmor', 'ocg'],
    }

    file { ['/srv/deployment','/srv/deployment/ocg']:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
    }

    file { $temp_dir:
        ensure  => directory,
        owner   => 'ocg',
        group   => 'ocg',
    }

    file { $output_dir:
        ensure  => directory,
        owner   => 'ocg',
        group   => 'ocg',
    }

    cron { "Clean up OCG output directory":
        ensure  => present,
        command => "find ${output_dir}* -mtime +5 -exec rm {} \\;",
        user    => 'ocg',
        hour    => 0,
        minute  => 0,
    }

    file { $postmortem_dir:
        ensure  => directory,
        owner   => 'ocg',
        group   => 'ocg',
    }

    cron { "Clean up OCG postmortem directory":
        ensure  => present,
        command => "find ${output_dir}* -mtime +3 -exec rm {} \\;",
        user    => 'ocg',
        hour    => 0,
        minute  => 0,
    }

    file { '/var/log/ocg':
        ensure  => directory,
        owner   => 'syslog',
        group   => 'ocg',
        mode    => '0664',
    }

    file { '/etc/logrotate.d/ocg':
        ensure  => present,
        source  => 'puppet:///modules/ocg/logrotate',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    rsyslog::conf { 'ocg':
        source   => 'puppet:///modules/ocg/ocg.rsyslog.conf',
        priority => 20,
    }
}
