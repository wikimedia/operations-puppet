# == Class: phabricator::apache
class phabricator::apache(
    $base_requirements,
    $settings,
    $serveradmin,
    $gitblit_servername,
    $phab_servername,
    $docroot,
    $serveraliases,
    $timezone,
) {
    $phabdir = $::phabricator::phabdir

    include apache::mod::php5
    include apache::mod::rewrite
    include apache::mod::headers

    # git.wikimedia.org hosts rewrite rules to redirect old gitblit urls to
    # equivilent diffusion urls.
    file { '/srv/git.wikimedia.org':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    apache::site { 'git.wikimedia.org':
        content => template('phabricator/gitblit_vhost.conf.erb'),
        require => File['/srv/git.wikimedia.org'],
        notify  => Service['apache2'],
    }
    
    apache::site { 'phabricator':
        content => template('phabricator/phabricator-default.conf.erb'),
        require => $base_requirements,
        notify  => Service['apache2'],
    }

    apache::conf { 'mpm_prefork':
        source => 'puppet:///modules/phabricator/apache/mpm_prefork.conf',
        notify => Service['apache2'],
    }

    # Robots.txt disallowing to crawl the alias domain
    if $serveraliases {
        file {"${phabdir}/robots.txt":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "User-agent: *\nDisallow: /\n",
        }
    }

    file { '/etc/php5/apache2/php.ini':
        content => template('phabricator/php.ini.erb'),
        notify  => Service['apache2'],
        require => Package['libapache2-mod-php5'],
    }

    file { '/etc/apache2/phabbanlist.conf':
        source  => 'puppet:///modules/phabricator/apache/phabbanlist.conf',
        require => Package['libapache2-mod-php5'],
        notify  => Service['apache2'],
    }
}
