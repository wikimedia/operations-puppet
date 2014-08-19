# the apache setup for the wikistats site
# expects:
# class {'webserver::php5': ssl => true; }
# to be on the node already, but can be enabled if not sharing
# with other roles already using it
# include webserver::php5-mysql to talk to mariadb on localhost (currently)
class wikistats::web (
    $wikistats_host,
    ) {

    # class {'webserver::php5': ssl => true; }
    # SSL not needed anymore, we are behind proxy meanwhile
    # include webserver::php5-mysql

    # Apache site from template
    apache::site { $wikistats_host:
        content => template('wikistats/apache/wikistats.erb'),
    }

    # document root
    file { '/var/www/wikistats':
        ensure  => directory,
        mode    => '0755',
        owner   => 'wikistatsuser',
        group   => 'www-data';
    }

    include ::apache::mod::rewrite

    file { '/etc/apache2/conf.d/namevirtualhost':
        source => 'puppet:///files/apache/conf.d/namevirtualhost',
        mode   => '0444',
        notify => Service['apache2'],
    }
}
