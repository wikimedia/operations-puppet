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
    $service_port = 80,
    $redis_host = 'localhost',
    $redis_port = 6379,
    $redis_password = '',
    $temp_dir = '/srv/deployment/ocg/tmp'
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

    if ( $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, "14.04") >= 0 ) {
        # Although we need NodeJS on the server, only ubuntu 14.04 currently
        # comes with it. On labs or 12.04 boxes it has to be installed by hand :(
        package { 'nodejs':
            ensure => present,
            notify => Service['ocg'],
        }
    }

    if ( $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, "12.04") >= 0 ) {
        # On ubuntu versions greater than 12.04 node is known as nodejs
        # This is exposed as a variable in the upstart configuration template
        $nodebin = 'nodejs'
    } else {
        $nodebin = 'node'
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
            'librsvg2-bin',
            'unzip',
            'zip',
        ]:
        ensure => present,
        before => Service['ocg']
    }

    service { 'ocg':
        provider   => upstart,
        ensure     => running,
        hasstatus  => false,
        hasrestart => false,
        require    => File['/etc/init/ocg.conf'],
    }

    file { '/etc/ocg':
        ensure => directory,
    }

    file { '/etc/ocg/mw-ocg-service.js':
        ensure  => present,
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

    file { '/etc/rsyslog.d/20-ocg.conf':
        ensure => present,
        source => 'puppet:///modules/ocg/ocg.rsyslog.conf',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        notify => Service['rsyslog'],
    }
}
