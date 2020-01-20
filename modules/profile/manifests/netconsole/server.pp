# Class: profile::netconsole::server
#
# This profile configures netconsole server on the host.
#
# Sample Usage:
#       include profile::netconsole::server
#
class profile::netconsole::server (
    Wmflib::Ensure $ensure = lookup('profile::netconsole::server::ensure', {default_value => 'absent'}),
    Wmflib::UserIpPort $port = lookup('profile::netconsole::server::port', {default_value => 6666}),
) {
    class { '::netconsole::server':
      ensure => $ensure,
      port   => $port,
    }
}
