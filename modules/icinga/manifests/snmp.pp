
class icinga::monitor::snmp {

    file { '/etc/snmp/snmptrapd.conf':
        source => 'puppet:///files/snmp/snmptrapd.conf.icinga',
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
    }
    file { '/etc/snmp/snmptt.conf':
        source => 'puppet:///files/snmp/snmptt.conf.icinga',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/init.d/snmptt':
        source => 'puppet:///files/snmp/snmptt.init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/init.d/snmptrapd':
        source => 'puppet:///files/snmp/snmptrapd.init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/init.d/snmpd':
        source => 'puppet:///files/snmp/snmpd.init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # snmp tarp stuff
    user { 'snmptt':
        home       => '/var/spool/snmptt',
        managehome => true,
        system     => true,
        groups     => [ 'snmptt', 'nagios' ]
    }

    package { 'snmpd':
        ensure => latest,
    }

    package { 'snmptt':
        ensure => latest,
    }

    service { 'snmptt':
        ensure     => running,
        hasstatus  => false,
        hasrestart => true,
        subscribe  => [
            File['/etc/snmp/snmptt.conf'],
            File['/etc/init.d/snmptt'],
            File['/etc/snmp/snmptrapd.conf']
        ],
    }

    service { 'snmptrapd':
        ensure    => running,
        hasstatus => false,
        subscribe => [
            File['/etc/init.d/snmptrapd'],
            File['/etc/snmp/snmptrapd.conf']
        ],
    }

    service { 'snmpd':
        ensure    => running,
        hasstatus => false,
        subscribe => File['/etc/init.d/snmpd'],
    }

    # FIXME: smptt crashes periodically on precise
    cron { 'restart_snmptt':
        ensure  => present,
        command => 'service snmptt restart >/dev/null 2>/dev/null',
        user    => 'root',
        hour    => [0, 4, 8, 12, 16, 20],
        minute  => 7,
    }

}

