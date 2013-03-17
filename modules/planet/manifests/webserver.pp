# webserver with SSL for a planet-venus setup
class planet::webserver {

  install_certificate{ "star.planet.${planet_domain_name}": }
  class {'webserver::php5': ssl => 'true'; }
  apache_module { rewrite: name => "rewrite" }

  Class['webserver::php5'] -> apache_module['rewrite'] -> Install_certificate["star.planet.${planet_domain_name}"]
}
