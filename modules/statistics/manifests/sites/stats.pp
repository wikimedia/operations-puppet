# stats.wikimedia.org
class statistics::sites::stats {
    require statistics::geowiki::data::private

    $site_name = 'stats.wikimedia.org'
    $docroot = "/srv/${site_name}/htdocs"
    $geowiki_private_directory = "${docroot}/geowiki-private"
    $geowiki_private_htpasswd_file = '/etc/apache2/htpasswd.stats-geowiki'

    # add htpasswd file for stats.wikimedia.org
    file { '/etc/apache2/htpasswd.stats':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///private/apache/htpasswd.stats',
    }

    # add htpasswd file for private geowiki data
    file { $geowiki_private_htpasswd_file:
        owner   => 'root',
        group   => 'www-data',
        mode    => '0640',
        source  => 'puppet:///private/apache/htpasswd.stats-geowiki',
    }

    # link geowiki checkout from docroot
    file { $geowiki_private_directory:
        ensure  => 'link',
        target  => "${misc::statistics::geowiki::data::private::geowiki_private_data_path}/datafiles",
        owner   => 'root',
        group   => 'www-data',
        mode    => '0750',
    }

    install_certificate{ $site_name: }

    file { '/etc/apache2/sites-available/stats.wikimedia.org':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('apache/sites/stats.wikimedia.org.erb'),

    file { '/etc/apache2/ports.conf':
        ensure  => 'present',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/apache/ports.conf.ssl',
    }

    apache_site { 'statswikimedia':
        name => 'stats.wikimedia.org',
    }

}

