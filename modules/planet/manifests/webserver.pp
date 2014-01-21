# sets up Apache with SSL for a planet-venus setup
class planet::webserver {

    # planet has its own star cert
    install_certificate{ "star.planet.${planet::planet_domain_name}": }

    # TODO to be replaced with new method in the future
    class { 'webserver::php5': ssl  => true; }
    apache_module { 'rewrite': name => 'rewrite' }

    # we do this because NameVirtualHost *:443 isn't there by default
    file { '/etc/apache2/ports.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/planet/ssl/ports.conf.ssl',
    }

    # dependencies for webserver setup
    Class['webserver::php5'] ->
    File['/etc/apache2/ports.conf'] ->
    apache_module['rewrite'] ->
    Install_certificate["star.planet.${planet::planet_domain_name}"]

}
