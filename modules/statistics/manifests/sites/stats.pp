# == Class statistics::sites::stats
# stats.wikimedia.org
class statistics::sites::stats {
    require ::statistics::web

    # TODO: make this a hiera param.
    $geowiki_private_data_bare_host = 'stat1003.eqiad.wmnet'

    class { '::geowiki':
        private_data_bare_host => $geowiki_private_data_bare_host
    }
    require ::geowiki::private_data

    $wikistats_web_directory       = '/srv/stats.wikimedia.org'
    $wikistats_v2_link             = "${wikistats_web_directory}/v2"
    $source_directory              = '/srv/src'
    $wikistats_source_directory    = '/srv/src/wikistats-v2'
    $geowiki_private_directory     = "${wikistats_web_directory}/htdocs/geowiki-private"
    $geowiki_private_htpasswd_file = '/etc/apache2/htpasswd.stats-geowiki'

    # add htpasswd file for stats.wikimedia.org
    file { '/etc/apache2/htpasswd.stats':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => secret('apache/htpasswd.stats'),
    }

    # add htpasswd file for private geowiki data
    file { $geowiki_private_htpasswd_file:
        owner   => 'root',
        group   => 'www-data',
        mode    => '0640',
        content => secret('apache/htpasswd.stats-geowiki'),
    }

    # link geowiki checkout from docroot
    file { $geowiki_private_directory:
        ensure => 'link',
        target => "${::geowiki::private_data_path}/datafiles",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0750',
    }

    apache::site { 'stats.wikimedia.org':
        content => template('statistics/stats.wikimedia.org.erb'),
    }

    file { $source_directory:
        ensure => directory,
        owner  => 'root',
        group  => 'www-data',
        mode   => '0755',
    }

    file { $wikistats_source_directory:
        ensure  => directory,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0755',
        require => File[$source_directory],
    }

    # stats.wikimedia.org/v2 (Wikistats 2.0) setup:
    # 1) wikistats v2 is cloned and has a built version available in /dist
    git::clone { 'wikistats-v2':
        ensure    => 'latest',
        directory => $wikistats_source_directory,
        branch    => 'master',
        origin    => 'https://phabricator.wikimedia.org/source/wikistats.git',
        owner     => 'root',
        group     => 'www-data',
        mode      => '0755',
        require   => File[$wikistats_source_directory],
    }

    # 2) it is then linked to serve at http://stats.wikimedia.org/v2
    file { $wikistats_v2_link:
        ensure => 'link',
        target => "${wikistats_source_directory}/dist",
    }
}
