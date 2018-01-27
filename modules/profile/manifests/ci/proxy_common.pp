# Basic configuration of Apache as a proxy
class profile::ci::proxy_common {

  class { '::apache': }
  class { '::apache::mod::php5': }
  class { '::apache::mod::proxy': }
  class { '::apache::mod::proxy_http': }

}
