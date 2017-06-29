# == Class statistics::sites::stats
# stats.wikimedia.org
class statistics::sites::stats {
    require ::statistics::web

    require ::geowiki::private_data
    include ::geowiki::params

    $wikistats_web_directory       = '/srv/stats.wikimedia.org'
    $wikistats_v2_link             = "${wikistats_web_directory}/v2"
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
        target => "${::geowiki::params::private_data_path}/datafiles",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0750',
    }

    apache::site { 'stats.wikimedia.org':
        content => template('statistics/stats.wikimedia.org.erb'),
    }

    # stats.wikimedia.org/v2 (Wikistats 2.0) setup
    # wikistats v2 is cloned and has a built version available in /dist
    git::clone { 'wikistats-v2':
        ensure    => 'latest',
        depth     => '1',
        directory => $wikistats_source_directory,
        origin    => 'https://phabricator.wikimedia.org/source/wikistats.git',
        owner     => 'root',
        group     => 'statistics-web-users',
        mode      => '0775',
    }

    # it is then linked to serve at http://stats.wikimedia.org/v2
    file { $wikistats_v2_link:
        ensure => 'link',
        target => "${wikistats_source_directory}/dist",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0750',
    }
}
