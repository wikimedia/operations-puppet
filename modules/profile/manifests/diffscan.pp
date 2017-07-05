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
  $ipranges=hiera('profile::diffscan::ipranges',{}),
  $emailto=hiera('profile::diffscan::emailto','root@wikimedia.org'),
  $groupname=hiera('profile::diffscan::groupname','diffscan'),
) {
    class { '::diffscan':
        ipranges  => $ipranges,
        emailto   => $emailto,
        groupname => $groupname,
    }
}
