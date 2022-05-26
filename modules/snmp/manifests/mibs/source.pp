# SPDX-License-Identifier: Apache-2.0
# This define uses snmp-mibs-downloader to download and install SNMP MIBs.
#
# Parameters:
#   $source
#       url of MIBs archive
#   $list
#       List of MIBs to install from the archive
#   $options
#       snmp-mibs-downloader extra config options
#
# Sample Usage:
#   snmp::mibs::source { 'example':
#       source  => 'https://example.com/mibs.tgz',
#       list    => 'puppet:///modules/snmp/example-mibs',
#       options =>  {
#           'PREFIX' => 'example/mib-',
#           'SUFFIX' => '.txt',
#                   },
#   }

define snmp::mibs::source(
  $source,
  $list,
  $options={},
) {

    $listname = "${title}list"

    # while Net-SNMP would be equally happy if we set this to $title, libsmi
    # isn't as smart and traverses directories non-recursively. We could either
    # modify /etc/smi.conf's path, or hardcode all of our sources to "site" but
    # making cleanup a little more difficult. This define doesn't support
    # ensure absent anyway, so do that for now.
    $destdir = 'site'

    file { "/etc/snmp-mibs-downloader/${title}.conf":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('snmp/mib.conf.erb'),
        require => Package['snmp-mibs-downloader'],
        notify  => Exec["download-mibs ${title}"],
    }

    file { "/etc/snmp-mibs-downloader/${listname}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => $list,
        require => Package['snmp-mibs-downloader'],
        notify  => Exec["download-mibs ${title}"],
    }

    exec { "download-mibs ${title}":
        path        => '/usr/sbin:/usr/bin:/sbin:/bin',
        require     => Package['snmp-mibs-downloader'],
        refreshonly => true,
    }

}
