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
    $host_name = $hostname,
    $service_port = 80,
    $redis_host = 'localhost',
    $redis_port = 6379,
    $redis_password = '',
    $temp_dir = '/srv/ocg/tmp'
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

    package { ['nodejs']:
        ensure => present,
        notify => Service['ocg'],
    }

    package {
        [
            'texlive-xetex',
            'texlive-latex-recommended',
            'texlive-latex-extra',
            'texlive-fonts-recommended',
            'texlive-lang-all',
            'latex-xcolor',
            'imagemagick',
            'librsvg2-bin',
            'zip',
            'unzip',
        ]:
        ensure => present,
        before => Service['ocg']
    }

    service { 'ocg':
        provider   => upstart,
        ensure     => running,
        hasstatus  => false,
        hasrestart => false,
        enable     => true,
        require    => File['/etc/init/ocg.conf'],
    }

    file { '/etc/ocg/mw-ocg-service.js':
        ensure  => present,
        content => template('ocg/mw-ocg-service.js.erb'),
        notify  => Service['ocg'],
    }

    file { '/etc/init/ocg.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => template('ocg/ocg.upstart.conf.erb'),
        require => [ User['ocg'], Group['ocg'] ],
        notify  => Service['ocg'],
    }

    file { $temp_dir:
        path    => $temp_dir,
        ensure  => directory,
        owner   => 'ocg',
        group   => 'ocg',
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
        user    => 'root',
        group   => 'root',
    }

    file { '/etc/rsyslog.d/20-ocg.conf':
        ensure => present,
        source => 'puppet:///modules/ocg/ocg.rsyslog.conf',
        mode   => '0444',
        user   => 'root',
        group  => 'root',
        notify => Service['rsyslog'],
    }
}
