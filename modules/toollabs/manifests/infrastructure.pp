# Class: toollabs::infrastructure
#
# This role configures the instance as part of the infrastructure
# where endusers are not expected to log in.  This class is not intended
# to be used directly, but is included from some other classes.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::infrastructure {

  file { "/etc/update-motd.d/40-infrastructure-banner":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/40-${instanceproject}-infrastructure-banner",
  }

  # Can you do this?
  # $::restricted_from = 'local-admin'
  # Nope.  Will this be visible from the template, then?
  $restricted_from = 'local-admin'
}

