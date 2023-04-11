# SPDX-License-Identifier: Apache-2.0
# @summary provisions scripts needed to sign ssh server certificates
# @param ensure ensurable param
# @param ca_key_id human-readable name for the CA key
# @param ca_key_secret path to pass to secret() to get the ca key
class profile::ssh::ca (
  Wmflib::Ensure      $ensure        = lookup('profile::ssh::ca::ensure',        {default_value => 'absent'}),
  Optional[String[1]] $ca_key_id     = lookup('profile::ssh::ca::ca_key_id',     {default_value => undef}),
  Optional[String[1]] $ca_key_secret = lookup('profile::ssh::ca::ca_key_secret', {default_value => undef}),
) {
  if $ensure == 'present' and !($ca_key_id and $ca_key_secret) {
    fail('profile::ssh::ca: must specify either both ca_key_id and ca_key_secret when present')
  }

  file { '/etc/ssh/ca-key-id.txt':
    ensure  => stdlib::ensure($ensure, 'file'),
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $ca_key_id,
  }

  $ca_content = ($ensure == 'present').bool2str(secret($ca_key_secret), '')
  file { '/etc/ssh/ca':
    ensure    => stdlib::ensure($ensure, 'file'),
    owner     => 'puppet',
    group     => 'puppet',
    mode      => '0400',
    content   => $ca_content,
    show_diff => false,
  }
}
