# @summary configure systemd-resolved
# @link https://www.freedesktop.org/software/systemd/man/resolved.conf.html
# @param ensure ensurable paramter
# @param dns A array of IPv4 and IPv6 addresses to use as system DNS servers
# @param fallback_dns A array of IPv4 and IPv6 addresses to use as the fallback
#                    DNS servers
# @param domains A array of search domains
# @param enable_llmnr enable Link-Local Multicast Name Resolution support, If set
#                    to "resolve", only resolution support is enabled
# @param enable_mdns enable Multicast DNS support, If set to "resolve", only
#                   resolution support is enabled
# @param dnssec enable dnssec validation
# @param enable_dtls enable DNS over TLS
# @param enable_cache enable the cache
# @param dns_stub_listener enable the stub listener
# @param read_etc_hosts read /etc/hosts, and try to resolve hosts or address by
#                       using the entries in the file before sending query to DNS
#                       servers.
class systemd::resolved (
    Wmflib::Ensure                            $ensure            = 'present',
    Array[Stdlib::IP::Address]                $dns               = [],
    Array[Stdlib::IP::Address]                $fallback_dns      = [],
    Array[String]                             $domains           = [],
    Variant[Enum['resolve'], Boolean]         $enable_llmnr      = false,
    Variant[Enum['resolve'], Boolean]         $enable_mdns       = false,
    Variant[Enum['allow-downgrade'], Boolean] $dnssec            = 'allow-downgrade',
    Variant[Enum['opportunistic'], Boolean ]  $enable_dtls       = false,
    Variant[Enum['no-negative'], Boolean]     $enable_cache      = true,
    Variant[Enum['tcp', 'udp'], Boolean]      $dns_stub_listener = true,
    Boolean                                   $read_etc_hosts    = true,
    Boolean                                   $link_resolv_conf  = true,
) {
    $enable = $ensure ? {
      'absent' => false,
      default  => true,
    }

    file{'/etc/resolv.conf':
        ensure => stdlib::ensure($link_resolv_conf, 'link'),
        target => '/run/systemd/resolve/stub-resolv.conf',
    }
    file {'/etc/systemd/resolved.conf':
      ensure  => file,
      content => template('systemd/resolved.conf.erb'),
      notify  => Service['systemd-resolved'],
    }
    service { 'systemd-resolved':
      ensure => stdlib::ensure($ensure, 'service'),
      enable => $enable,
    }
}
