# Basic configuration of Apache as a proxy
class contint::proxy_common {

  class {'webserver::php5': ssl => false; }

  include ::apache::mod::proxy
  include ::apache::mod::proxy_http

}
