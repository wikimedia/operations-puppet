# == Class statistics::sites::stats
#
# stats.wikimedia.org's httpd configuration
#
class statistics::sites::stats {
    require ::statistics::web

    $wikistats_web_directory       = '/srv/stats.wikimedia.org'
    $wikistats_v2_link             = "${wikistats_web_directory}/htdocs/v2"
    $source_directory              = '/srv/src'
    $wikistats_source_directory    = '/srv/src/wikistats-v2'
    $geowiki_private_directory     = "${wikistats_web_directory}/htdocs/geowiki-private"
    $geowiki_private_htpasswd_file = '/etc/apache2/htpasswd.stats-geowiki'

    # add htpasswd file for stats.wikimedia.org
    file { '/etc/apache2/htpasswd.stats':
        owner     => 'root',
        group     => 'root',
        mode      => '0644',
        content   => secret('apache/htpasswd.stats'),
        show_diff => false,
    }

    # add htpasswd file for private geowiki data
    # TODO: remove this when the geowiki site is removed.
    file { $geowiki_private_htpasswd_file:
        ensure    => 'present',
        owner     => 'root',
        group     => 'www-data',
        mode      => '0640',
        content   => secret('apache/htpasswd.stats-geowiki'),
        show_diff => false,
    }

    # Allow rsync to /srv/stats.wikimedia.org.
    # Files are pushed here by ezachte for wikistats 1 updates.
    rsync::server::module { 'stats.wikimedia.org':
        # Ezachte is no longer updating stats.wikimedia.org.
        # Ensure it is no longer writable by remote rsync from statistics servers.
        # https://phabricator.wikimedia.org/T205113#5062563
        ensure      => 'absent',
        path        => $wikistats_web_directory,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $::statistics::servers,
        auto_ferm   => true,
    }

    httpd::site { 'stats.wikimedia.org':
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
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wikistats2',
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
