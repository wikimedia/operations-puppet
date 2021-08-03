# == Class statistics::sites::stats
#
# stats.wikimedia.org's httpd configuration.
#
# stats.wikimedia.org was originally Erik Zachte's wikistats files.
# We call this wikistats v1.  wikistats v2 has superseded wikistats v1,
# but we still want to keep the wikistats v1 files and URLs around, as
# they are used and referenced by the Wikimedia community.
#
class statistics::sites::stats {
    require ::statistics::web

    $wikistats_web_directory       = '/srv/stats.wikimedia.org'
    $geowiki_private_directory     = "${wikistats_web_directory}/htdocs/geowiki-private"
    $geowiki_private_htpasswd_file = '/etc/apache2/htpasswd.stats-geowiki'

    # added due to this error: https://phabricator.wikimedia.org/T285355#7256778
    file {[$wikistats_web_directory, "${wikistats_web_directory}/htdocs"]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0775',
    }

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

    # stats.wikimedia.org (Wikistats 2.0) setup:
    $wikistats_source_directory    = '/srv/src/wikistats-v2'
    file { ['/srv/src', $wikistats_source_directory]:
        ensure => directory,
        owner  => 'root',
        group  => 'www-data',
        mode   => '0755',
    }

    # wikistats-v2 is cloned and has a built version available in /dist
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

    # It is then linked to serve at http://stats.wikimedia.org/v2
    # TO BE REMOVED once redirect from /v2 -> / is set up.
    file { "${wikistats_web_directory}/htdocs/v2":
        ensure  => 'link',
        target  => "${wikistats_source_directory}/dist",
        require => File[$wikistats_source_directory],
    }

    # We want to serve wikistats 2 from the root stats.wikimedia.org domain.
    # wikistats 2 has only 2 entry URLs, index.html and assets-v2.  Symlink them
    # from the docroot.
    file { "${wikistats_web_directory}/htdocs/index.html":
        ensure  => 'link',
        target  => "${wikistats_source_directory}/dist/index.html",
        require => File[$wikistats_source_directory],
    }
    file { "${wikistats_web_directory}/htdocs/assets-v2":
        ensure  => 'link',
        target  => "${wikistats_source_directory}/dist/assets-v2",
        require => File[$wikistats_source_directory],
    }

    # Apache site for stats.wikimedia.org
    httpd::site { 'stats.wikimedia.org':
        content => template('statistics/stats.wikimedia.org.erb'),
    }
}
