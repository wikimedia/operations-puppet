# Class: profile::netconsole
#
# This profile configures netconsole on the host.
#
# Sample Usage:
#       include profile::netconsole
#
class profile::netconsole (
    Wmflib::Ensure $ensure = lookup('profile::netconsole::ensure'),
    Optional[Stdlib::Ipv4] $remote_ip = lookup('profile::netconsole::remote_ip', {default_value => undef}),
    Optional[Stdlib::MAC] $remote_mac = lookup('profile::netconsole::remote_mac', {default_value => undef}),
) {
    class { '::netconsole':
      ensure     => $ensure,
      dev_name   => $::interface_primary,
      local_ip   => $::ipaddress,
      remote_ip  => $remote_ip,
      remote_mac => $remote_mac,
    }
}
