# SPDX-License-Identifier: Apache-2.0
# @summary file parameters to get a signed hostkey
# @param $hosts List of hostnames to get signatures for
# @param $type key type, like ed25519
define ssh::server::ca_signed_hostkey (
  Array[Stdlib::Host] $hosts,
  Ssh::KeyType        $type,
  Wmflib::Ensure      $ensure = present,
) {
  if $ensure == 'present' {
    $all_certs = $::facts['ssh_ca_host_certificate']
    if $all_certs and $all_certs[$title] {
      $signed_cert_data = $all_certs[$title]

      $signed_cert_needs_regeneration = (
        $signed_cert_data['principals'].sort != $hosts.sort
        or $signed_cert_data['lifetime_remaining_seconds'] < 86400 * 14
      )
    } else {
      $signed_cert_needs_regeneration = true
    }

    $pubkey = "${::facts['ssh'][$type]['type']} ${::facts['ssh'][$type]['key']}\n"
    $signed_cert_content = $signed_cert_needs_regeneration ? {
      true    => ssh::ssh_sign_host_certificate($pubkey, $hosts),
      default => undef,
    }
  } else {
    $signed_cert_content = undef
  }

  file { $title:
    ensure    => stdlib::ensure($ensure, 'file'),
    owner     => 'root',
    group     => 'root',
    mode      => '0444',
    show_diff => false,
    replace   => $signed_cert_content != undef,
    content   => $signed_cert_content,
  }
}
