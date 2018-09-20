# Class snmp::mibs
#
# Install snmp-mibs-downloader.
# Download and install Juniper MIBs from Juniper's (unsigned) archive.
#
# Sample Usage:
#   include ::snmp::mibs

class snmp::mibs {
    require ::snmp

    package { 'snmp-mibs-downloader':
        ensure => present,
    }

    file { '/etc/snmp-mibs-downloader/snmp-mibs-downloader.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/snmp/snmp-mibs-downloader.conf',
        require => Package['snmp-mibs-downloader'],
    }

    snmp::mibs::source { 'juniper':
        source  => 'https://www.juniper.net/documentation/software/junos/junos182/juniper-mibs-18.2R1.9.tgz',
        list    => 'puppet:///modules/snmp/juniper-mibs',
        options => {
            'PREFIX' => 'JuniperMibs/mib-',
            'SUFFIX' => '.txt',
        },
    }

}
