# Class: profile::netconsole::client
#
# This profile configures netconsole client on the host.
#
# Sample Usage:
#       include profile::netconsole::client
#
class profile::netconsole::client (
    Wmflib::Ensure $ensure = lookup('profile::netconsole::client::ensure'),
    Optional[Stdlib::Ipv4] $remote_ip = lookup('profile::netconsole::client::remote_ip', {default_value => undef}),
    Optional[Stdlib::MAC] $remote_mac = lookup('profile::netconsole::client::remote_mac', {default_value => undef}),
) {
    class { '::netconsole::client':
      ensure     => $ensure,
      dev_name   => $::interface_primary,
      local_ip   => $::ipaddress,
      remote_ip  => $remote_ip,
      remote_mac => $remote_mac,
    }
}
