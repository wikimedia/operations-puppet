# sets up Apache with SSL for a planet-venus setup
class planet::webserver {

    # TODO to be replaced with new method in the future
    class { 'webserver::php5': }
    include ::apache::mod::rewrite
    # so we can vary on X-Forwarded-Proto when behind misc-web
    include ::apache::mod::headers

    # we do this because NameVirtualHost *:443 isn't there by default
    file { '/etc/apache2/ports.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/planet/apache/ports.conf.ssl',
    }

    # dependencies for webserver setup
    Class['webserver::php5'] ->
    File['/etc/apache2/ports.conf'] ->
    Class['::apache::mod::rewrite']

}
