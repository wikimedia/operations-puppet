# == Class statistics::sites::stats
# stats.wikimedia.org
class statistics::sites::stats {
    require ::statistics::web

    require ::geowiki::private_data
    include ::geowiki::params

    $geowiki_private_directory     = '/srv/stats.wikimedia.org/htdocs/geowiki-private'
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
}
