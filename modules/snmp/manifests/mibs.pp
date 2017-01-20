#
class snmp::mibs {
    package { 'snmp-mibs-downloader':
        ensure => present,
    }

    snmp::mibs::source { 'juniper':
        source  => 'http://www.juniper.net/techpubs/software/junos/junos161/juniper-mibs-16.1R3.10.tgz',
        list    => 'puppet:///modules/snmp/juniper-mibs',
        options => {
            'PREFIX' => 'JuniperMibs/mib-',
            'SUFFIX' => '.txt',
        },
    }

}
