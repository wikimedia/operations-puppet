# webserver with SSL for a planet-venus setup
class planet::webserver {

  install_certificate{ "star.planet.${planet_domain_name}": }
  class {'webserver::php5': ssl => 'true'; }
  apache_module { rewrite: name => "rewrite" }

  file {
    '/etc/apache2/ports.conf':
      ensure => present,
      mode   => '0444',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/planet/ssl/ports.conf.ssl';
}

  Class['webserver::php5'] -> File['/etc/apache2/ports.conf'] -> apache_module['rewrite'] -> Install_certificate["star.planet.${planet_domain_name}"]
}
