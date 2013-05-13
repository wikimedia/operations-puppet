# A http proxy in front of Zuul status page
class contint::proxy_zuul {

  include proxy_common

  file {
    '/etc/apache2/conf.d/zuul_proxy':
      ensure => absent,
  }

  file {
    '/etc/apache2/zuul_proxy':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/contint/apache/proxy_zuul',
  }

}
