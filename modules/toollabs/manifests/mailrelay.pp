# Class: toollabs::mailrelay
#
# This role sets up a mail relay in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::mailrelay($maildomain) inherits toollabs {
  include toollabs::infrastructure

  file { "$store/mail-relay":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => template("toollabs/mail-relay.erb"),
  }

  File <| title == '/etc/exim4/exim4.conf' |> {
    source => undef,
    content => template("toollabs/exim4.conf.erb"),
  }
}

