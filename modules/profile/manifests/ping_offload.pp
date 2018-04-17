# sets up the ping offload servers - T190090
# == Parameters:
# [*target_ips*]
#   IPs or AnyIP subnets to configure on the host's loopback interface.
#   In order to reply to ICMP requests messages.
#   Default: None
class profile::ping_offload(
  Hash[String, Stdlib::Compat::Ip_address] $target_ips = hiera('profile::ping_offload::target_ips', undef),
  ) {
  $target_ips.each |$ip_descr, $iface_ip| {
    interface::ip { $ip_descr:
      address   => $iface_ip,
      interface => 'lo',
      options   => 'label lo:ping_offload'
    }
  }
}
