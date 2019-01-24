# === Class base::puppet::pins
#
# Pins packages to the needed versions for of puppet and facter
# We still rely on facter 2.4 (Debian buster uses version 3 by default,
# so we're using a custom build to use the same version across all 
# supported distributions)

class base::puppet::pins {
  $facter_pin_to = $facts['lsbdistcodename'] ? {
    'buster' => 'buster-wikimedia',
    'jessie' => 'jessie-backports',
    default  => undef
  }
  $puppet_pin_to = $facts['lsbdistcodename'] ? {
    'jessie' => 'jessie-backports',
    default  => undef
  }
  if $puppet_pin_to {
    apt::pin { 'puppet-all':
      pin      => "release n=${puppet_pin_to}",
      package  => 'puppet*',
      priority => '1001',
      before   => Package['puppet'],
    }
  }
  if $facter_pin_to {
    apt::pin { 'facter':
      pin      => "release n=${facter_pin_to}",
      package  => 'facter',
      priority => '1001',
      before   => Package['facter'],
    }
  }
}
