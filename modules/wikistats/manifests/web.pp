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
    file { "/etc/apache2/sites-available/${wikistats_host}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('wikistats/apache/wikistats.erb');
    }

    # document root
    file { '/var/www/wikistats':
        ensure  => directory,
        mode    => '0755',
        owner   => 'wikistats',
        group   => 'www-data';
    }

    apache_module { 'mod_rewrite': name => 'rewrite' }

    apache_confd { 'namevirtualhost':
        install => true,
        name    => 'namevirtualhost',
    }

    apache_site { 'wikistats': name => $wikistats_host }

}
