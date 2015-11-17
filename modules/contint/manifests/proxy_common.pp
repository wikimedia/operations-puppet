# Basic configuration of Apache as a proxy
class contint::proxy_common {

  include ::apache
  include ::apache::mod::php5
  include ::apache::mod::proxy
  include ::apache::mod::proxy_http

}
