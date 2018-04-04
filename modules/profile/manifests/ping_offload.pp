# sets up the ping offload servers - T190090
# == Parameters:
# [*target_ips*]
#   IPs to configure on the host's loopback interface.
#   In order to reply to ICMP requests messages.
#   Default: None
class profile::ping_offload(
  $target_ips = hiera('profile::ping_offload::target_ips', undef),
  ) {

  if $target_ips {
      $lo_ips_defaults = {
          interface => 'lo',
          options   => 'label lo:ping_offload',
      }
      create_resources(interface::ip, $target_ips, $lo_ips_defaults)
  }
}
