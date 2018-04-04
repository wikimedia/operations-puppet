# sets up the ping offload servers - T190090
# == Parameters:
# [*target_ips*]
#   IPs to configure on the host's loopback interface.
#   In order to reply to ICMP requests messages.
#   Default: None
class profile::ping_offload(
  $target_ips = hiera('profile::ping_offload::target_ips', undef),
  ) {
  interface::ip { $target_ips:
    interface => 'lo',
    options   => 'label lo:ping_offload'
  }
}
