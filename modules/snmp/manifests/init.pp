# SPDX-License-Identifier: Apache-2.0
# Class: snmp
#
# Install the set of basic SNMP client tools (via the snmp package)
# and configure it to find MIB in extra directories.
#
# Sample Usage:
#   include ::snmp

class snmp {
    ensure_packages('snmp')

    file { '/etc/snmp/snmp.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/snmp/snmp.conf',
    }

}
