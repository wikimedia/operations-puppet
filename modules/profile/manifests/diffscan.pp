# SPDX-License-Identifier: Apache-2.0
# == Class: diffscan
#
# This class installs & manages diffscan,
# an nmap wrapper for differential port scans.
# See https://github.com/ameihm0912/diffscan2
#
# == Parameters
#
# [*ipranges*]
#   The list of IP/masks to scan. See nmap doc for accepted formats.
#
# [*emailto*]
#   Diff emails recipient. Defaults to "root".
#
# [*groupname*]
#   An identifier to distinguish between several instances.
#   Defaults to "diffscan".
#
class profile::diffscan(
    Hash[String[1], Profile::Diffscan::Instance] $instances = lookup('profile::diffscan::instances', {default_value => {}}),
) {
    $instances.each |String[1] $groupname, Profile::Diffscan::Instance $config| {
        diffscan::instance { $groupname:
            ipranges => $config['ranges'],
            emailto  => $config['email'],
        }
    }
}
