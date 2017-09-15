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
    $host_name = $::fqdn,
    $decommission = hiera('ocg::decommission', false),
    $service_port = 8000,
    $redis_host = 'localhost',
    $redis_port = 6379,
    $redis_password = '',
    $statsd_host = 'localhost',
    $statsd_port = 8125,
    $graylog_host = 'localhost',
    $graylog_port = 12201,
    $temp_dir = '/srv/deployment/ocg/tmp',
    $output_dir = '/srv/deployment/ocg/output',
    $postmortem_dir = '/srv/deployment/ocg/postmortem',
    $log_dir = '/srv/deployment/ocg/log'
) {
    scap::target { 'ocg/ocg':
        deploy_user => 'deploy-service',
    }

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

    require_package('nodejs')
    $nodebin = '/usr/bin/nodejs-ocg'
    apparmor::hardlink { $nodebin:
        target => '/usr/bin/nodejs',
    }

    if os_version('debian >= jessie || ubuntu >= wily') {
        $imagemagick_dir = '/etc/ImageMagick-6'
    } else {
        $imagemagick_dir = '/etc/ImageMagick'
    }

    include ::imagemagick::install

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
            'fonts-farsiweb',
            'fonts-nafees',
            'fonts-arphic-uming',
            'fonts-arphic-ukai',
            'fonts-droid',
            'fonts-baekmuk',
            'latex-xcolor',
            'lmodern',
            'poppler-utils',
            'libjpeg-progs',
            'librsvg2-bin',
            'djvulibre-bin',
            'unzip',
            'zip',
        ]:
        ensure => present,
        before => Service['ocg']
    }


    if os_version('ubuntu >= trusty') {
        require_package('ttf-devanagari-fonts', 'ttf-malayalam-fonts', 'ttf-indic-fonts-core')
    }

    if os_version('debian >= jessie') {
        require_package('fonts-deva', 'fonts-mlym', 'fonts-beng', 'fonts-gujr', 'fonts-knda', 'fonts-orya', 'fonts-guru', 'fonts-taml', 'fonts-telu', 'fonts-gujr-extra')
    }

    if $::initsystem == 'systemd' {
        $ocg_provider = 'systemd'
        $ocg_require = '/etc/systemd/system/ocg.service'
        $ocg_log_grp = 'adm'

        file { '/etc/systemd/system/ocg.service':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/ocg/ocg.service',
            require => User['ocg'],
            notify  => Service['ocg'],
        }

    } else {
        $ocg_provider = 'upstart'
        $ocg_require = '/etc/init/ocg.conf'
        $ocg_log_grp = 'syslog'

        file { '/etc/init/ocg.conf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('ocg/ocg.upstart.conf.erb'),
            require => User['ocg'],
            notify  => Service['ocg'],
        }
    }

    service { 'ocg':
        ensure     => running,
        provider   => $ocg_provider,
        hasstatus  => false,
        hasrestart => false,
        require    => [
            File[$ocg_require],
            Package['ocg/ocg'],
        ],
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

    # Change this if you change the value of $nodebin
    include apparmor
    $nodebin_dots = regsubst($nodebin, '/', '.', 'G')

    file { "/etc/apparmor.d/${nodebin_dots}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('ocg/usr.bin.nodejs.apparmor.erb'),
        notify  => Service['apparmor', 'ocg'],
    }

    # FIXME: only for migration purposes, remove --2015-01-09
    file { '/etc/apparmor.d/usr.bin.nodejs-pdf':
        ensure  => absent,
        require => File["/etc/apparmor.d/${nodebin_dots}"],
    }

    file { ['/srv/deployment','/srv/deployment/ocg']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    if $temp_dir == '/srv/deployment/ocg/tmp' {
        file { $temp_dir:
            ensure => directory,
            owner  => 'ocg',
            group  => 'ocg',
        }
    } else {
        File[$temp_dir] -> Class['ocg']
    }

    file { $output_dir:
        ensure => directory,
        owner  => 'ocg',
        group  => 'ocg',
    }

    file { $postmortem_dir:
        ensure => directory,
        owner  => 'ocg',
        group  => 'ocg',
    }

    file { $log_dir:
        ensure => directory,
        # matches /var/log
        mode   => '0775',
        owner  => 'root',
        group  => $ocg_log_grp,
    }

    # help unfamiliar sysadmins find the logs
    file { '/var/log/ocg':
        ensure => link,
        target => $log_dir,
    }

    # makes some basic logfiles readable for non-roots
    # in labs this is used by default in role/labs
    if $::realm == 'production' {
        class { 'base::syslogs':
            readable => true,
            logfiles => ['syslog','messages','ocg.log'],
        }
    }

    logrotate::conf { 'ocg':
        ensure => present,
        source => 'puppet:///modules/ocg/logrotate',
    }

    # run logrotate hourly, instead of daily, to ensure that log size
    # limits are enforced more-or-less accurately
    file { '/etc/cron.hourly/logrotate.ocg':
        ensure => link,
        target => '/etc/cron.daily/logrotate',
    }

    rsyslog::conf { 'ocg':
        source   => 'puppet:///modules/ocg/ocg.rsyslog.conf',
        priority => 20,
    }
}
