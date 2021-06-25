# @summary install and configures Dragonfly dfdaemon and dfget to be used as HTTPS proxy by local docker
#
# @supernodes
#
# @dfdaemon_ssl_cert
#
# @dfdaemon_ssl_key
#
# @docker_registry_fqdn
#
# @proxy_urls_regex
#
class dragonfly::dfdaemon (
    Array[String]        $supernodes,
    Stdlib::Absolutepath $dfdaemon_ssl_cert,
    Stdlib::Absolutepath $dfdaemon_ssl_key,
    Stdlib::Fqdn         $docker_registry_fqdn,
    Array[String]        $proxy_urls_regex = ['blobs/sha256.*'],
) {
  ensure_packages('dragonfly-dfdaemon')

  # This is needed to hijack HTTPS requests to docker-registry
  sslcert::certificate { $docker_registry_fqdn:
      ensure       => present,
      skip_private => false,
      before       => Service['dragonfly-dfdaemon'],
  }

  # TODO: Custom type for supernode list
  #       host:port(default:8002)=weight(default:1)
  file { '/etc/dragonfly/dfget.yml':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dragonfly/dfget.yml.erb'),
      notify  => Service['dragonfly-dfdaemon'],
  }
  file { '/etc/dragonfly/dfdaemon.yml':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dragonfly/dfdaemon.yml.erb'),
      notify  => Service['dragonfly-dfdaemon'],
  }

  # Configure the docker daemon to use the local dfdaemon as https_proxy
  $proxy_host = '127.0.0.1:65001'
  systemd::unit{'docker':
      override => true,
      restart  => true,
      content  => "[Service]\nEnvironment=\"HTTPS_PROXY=http://${proxy_host}\"",
  }

  service { 'dragonfly-dfdaemon':
      ensure  => running,
  }
}
