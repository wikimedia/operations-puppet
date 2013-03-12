# Basic configuration of Apache as a proxy
class contint::proxy_common {

  class {'webserver::php5': ssl => true; }

  apache_module { 'contint_mod_proxy': name => 'proxy' }
  apache_module { 'contint_mod_proxy_http': name => 'proxy_http' }

}
