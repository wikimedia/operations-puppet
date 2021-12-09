# Class: profile::netconsole::client
#
# This profile configures netconsole client on the host.
# Note the broadcast MAC is used to allow for cross-row communication.
#
# Sample Usage:
#       * Add 'include profile::netconsole::client' in your role
#       * Set 'profile::netconsole::client::ensure: present' where needed in hieradata/
#
#
class profile::netconsole::client (
    Wmflib::Ensure $ensure = lookup('profile::netconsole::client::ensure'),
    Optional[Stdlib::IP::Address::V4] $remote_ip = lookup('profile::netconsole::client::remote_ip', {default_value => undef}),
    Optional[Stdlib::MAC] $remote_mac = lookup('profile::netconsole::client::remote_mac', {default_value => 'ff:ff:ff:ff:ff:ff'}),
) {
    class { '::netconsole::client':
      ensure     => $ensure,
      dev_name   => $::interface_primary,
      local_ip   => $::ipaddress,
      remote_ip  => $remote_ip,
      remote_mac => $remote_mac,
    }
}
