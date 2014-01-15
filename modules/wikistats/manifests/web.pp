# the apache setup for the wikistats site
# expects:
# class {'webserver::php5': ssl => true; }
# to be on the node already, but can be enabled if not sharing
# with other roles already using it
# include webserver::php5-mysql to talk to mariadb on localhost (currently)
class wikistats::web (
    $wikistats_host,
    $wikistats_ssl_cert,
    $wikistats_ssl_key
    ) {

    # class {'webserver::php5': ssl => true; }
    # include webserver::php5-mysql

    file {
        "/etc/apache2/sites-available/${wikistats_host}":
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('wikistats/apache/wikistats.erb');
        '/etc/apache2/ports.conf':
            ensure  => present,
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///wikistats/apache/ports.conf';
        '/var/www/wikistats':
            ensure  => directory,
            mode    => '0755',
            owner   => 'wikistats',
            group   => 'www-data';
    }

    apache_module { 'modrewrite': name => 'rewrite' }

    apache_confd { 'namevirtualhost':
        install => true,
        name    => 'namevirtualhost',
    }

    apache_site { 'wikistats': name => $wikistats_host }

}
