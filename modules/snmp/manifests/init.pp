# SPDX-License-Identifier: Apache-2.0
# Class: snmp
#
# Install the set of basic SNMP client tools (via the snmp package)
# and configure it to find MIB in extra directories.
#
# Sample Usage:
#   include ::snmp

class snmp {
    ensure_packages(['snmp', 'snmp-mibs-downloader'])

    file { '/etc/snmp/snmp.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/snmp/snmp.conf',
    }

    # make libsmi aware of snmp-mibs-downloader path
    # See also https://phabricator.wikimedia.org/T359198
    file_line { 'libsmi-mibs':
        ensure => present,
        path   => '/etc/smi.conf',
        line   => 'path :/var/lib/mibs/site  # Managed by puppet',
    }
}
