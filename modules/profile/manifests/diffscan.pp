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
  Array[Stdlib::IP::Address] $ipranges = lookup('profile::diffscan::ipranges'),
  String $emailto                      = lookup('profile::diffscan::emailto'),
  String $groupname                    = lookup('profile::diffscan::groupname'),
) {
    class { '::diffscan':
        ipranges  => $ipranges,
        emailto   => $emailto,
        groupname => $groupname,
    }
}
