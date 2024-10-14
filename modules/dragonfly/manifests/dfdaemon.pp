# SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configures Dragonfly dfdaemon and dfget to be used as HTTPS proxy by local docker.
#
# @param supernodes
#   List of dragonfly supernodes in the format: "host:port(default:8002)=weight(default:1)".
#
# @param dfdaemon_ssl_cert
#   The certificate used to secure connections to dfdaemon (needs alt names 127.0.0.1, ::1 and localhost).
#   It is also used to hijack TLS connections to the source registry, so it needs to include an alt name for
#   @docker_registry_fqdn as well.
#
# @param dfdaemon_ssl_key
#   Key for the @dfdaemon_ssl_cert.
#
# @param docker_registry_fqdn
#   FQDN of the source docker registry. dfdaemon will hijack connections to this registry when used as HTTPS_PROXY.
#
# @param proxy_urls_regex
#   A list of URL regexes for that requests should be send though the P2P network-
#
# @param ratelimit
#   Rate network bandwith rate limit for the dfget calls in format of G(B)/g/M(B)/m/K(B)/k/B, pure number will also
#   be parsed as Byte.
#
class dragonfly::dfdaemon (
  Wmflib::Ensure       $ensure,
  Array[String]        $supernodes,
  Stdlib::Absolutepath $dfdaemon_ssl_cert,
  Stdlib::Absolutepath $dfdaemon_ssl_key,
  Stdlib::Fqdn         $docker_registry_fqdn,
  Array[String]        $proxy_urls_regex = ['blobs/sha256.*'],
  String               $ratelimit = '100M',
) {
  ensure_packages(['dragonfly-dfdaemon', 'dragonfly-dfget'], { 'ensure' => $ensure })

  # TODO: Custom type for supernode list
  #       host:port(default:8002)=weight(default:1)
  file { '/etc/dragonfly/dfget.yml':
    ensure  => stdlib::ensure($ensure, 'file'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dragonfly/dfget.yml.erb'),
    notify  => Service['dragonfly-dfdaemon'],
  }
  file { '/etc/dragonfly/dfdaemon.yml':
    ensure  => stdlib::ensure($ensure, 'file'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dragonfly/dfdaemon.yml.erb'),
    notify  => Service['dragonfly-dfdaemon'],
  }

  service { 'dragonfly-dfdaemon':
    ensure  => stdlib::ensure($ensure, 'service'),
  }
}
