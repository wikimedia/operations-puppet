#
class snmp {
    package { 'snmp':
        ensure => present,
    }
    file { '/etc/snmp/snmp.conf':
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/snmp/snmp.conf',
    }
}
