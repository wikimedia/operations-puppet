# SPDX-License-Identifier: Apache-2.0
# === Class profile::tofurkey
#
# Note that changing the rotation interval will invalidate all FTO cookies, for EVERYONE.
class profile::tofurkey(
    Boolean                         $enabled   = lookup('profile::tofurkey::enable_tfo_key_rotation', {'default_value' => false}),
    Optional[String]                $keyfile   = lookup('profile::tofurkey::keyfile', {'default_value' => undef}),
    Integer[10,604800]              $interval  = lookup('profile::tofurkey::rotation_interval', {'default_value' => 604800})
) {

    $service_name = 'tofurkey'
    if $keyfile {
        class { 'tofurkey':
            enabled           => $enabled,
            keyfile           => $keyfile,
            rotation_interval => $interval,
        }
    }
}

