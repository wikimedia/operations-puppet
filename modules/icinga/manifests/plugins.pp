
class icinga::plugins {

    require icinga::packages

    file { '/usr/lib/nagios':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers/submit_check_result':
        source => 'puppet:///icinga/submit_check_result',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/var/lib/nagios/rm':
      ensure => directory,
      owner  => 'icinga',
      group  => 'nagios',
      mode   => '0775',
    }
    file { '/etc/nagios-plugins':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    file { '/etc/nagios-plugins/config':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/nagios-plugins/config/apt.cfg':
        source => 'puppet:///icinga/plugin-config/apt.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/breeze.cfg':
        source => 'puppet:///icinga/plugin-config/breeze.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/dhcp.cfg':
        source => 'puppet:///icinga/plugin-config/dhcp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/disk-smb.cfg':
        source => 'puppet:///icinga/plugin-config/disk-smb.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/disk.cfg':
        source => 'puppet:///icinga/plugin-config/disk.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/dns.cfg':
        source => 'puppet:///icinga/plugin-config/dns.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/dummy.cfg':
        source => 'puppet:///icinga/plugin-config/dummy.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/flexlm.cfg':
        source => 'puppet:///icinga/plugin-config/flexlm.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ftp.cfg':
        source => 'puppet:///icinga/plugin-config/ftp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/hppjd.cfg':
        source => 'puppet:///icinga/plugin-config/hppjd.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/http.cfg':
        source => 'puppet:///icinga/plugin-config/http.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ifstatus.cfg':
        source => 'puppet:///icinga/plugin-config/ifstatus.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ldap.cfg':
        source => 'puppet:///icinga/plugin-config/ldap.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/load.cfg':
        source => 'puppet:///icinga/plugin-config/load.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/mail.cfg':
        source => 'puppet:///icinga/plugin-config/mail.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/mrtg.cfg':
        source => 'puppet:///icinga/plugin-config/mrtg.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/mysql.cfg':
        source => 'puppet:///icinga/plugin-config/mysql.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/netware.cfg':
        source => 'puppet:///icinga/plugin-config/netware.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/news.cfg':
        source => 'puppet:///icinga/plugin-config/news.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/nt.cfg':
        source => 'puppet:///icinga/plugin-config/nt.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ntp.cfg':
        source => 'puppet:///icinga/plugin-config/ntp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/pgsql.cfg':
        source => 'puppet:///icinga/plugin-config/pgsql.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ping.cfg':
        source => 'puppet:///icinga/plugin-config/ping.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/procs.cfg':
        source => 'puppet:///icinga/plugin-config/procs.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/radius.cfg':
        source => 'puppet:///icinga/plugin-config/radius.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/real.cfg':
        source => 'puppet:///icinga/plugin-config/real.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/rpc-nfs.cfg':
        source => 'puppet:///icinga/plugin-config/rpc-nfs.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/snmp.cfg':
        source => 'puppet:///icinga/plugin-config/snmp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ssh.cfg':
        source => 'puppet:///icinga/plugin-config/ssh.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/tcp_udp.cfg':
        source => 'puppet:///icinga/plugin-config/tcp_udp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/telnet.cfg':
        source => 'puppet:///icinga/plugin-config/telnet.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/users.cfg':
        source => 'puppet:///icinga/plugin-config/users.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/vsz.cfg':
        source => 'puppet:///icinga/plugin-config/vsz.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    File <| tag == nagiosplugin |>

    # WMF custom service checks
    file { '/usr/lib/nagios/plugins/check_mysql-replication.pl':
        source => 'puppet:///icinga/check_mysql-replication.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_cert':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///icinga/check_cert',
    }
    file { '/usr/lib/nagios/plugins/check_all_memcached.php':
        source => 'puppet:///icinga/check_all_memcached.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_bad_apaches':
        source => 'puppet:///icinga/check_bad_apaches',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_dsh_groups':
        source => 'puppet:///icinga/check_dsh_groups',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_longqueries':
        source => 'puppet:///icinga/check_longqueries',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_MySQL.php':
        source => 'puppet:///icinga/check_MySQL.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_solr':
        source => 'puppet:///icinga/check_solr',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_ssl_cert':
        source => 'puppet:///icinga/check_ssl_cert/check_ssl_cert',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_nrpe':
        source => 'puppet:///icinga/check_nrpe',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_ram.sh':
        source => 'puppet:///icinga/check_ram.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_graphite':
        source => 'puppet:///icinga/check_graphite',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    # Include check_elasticsearch from elasticsearch module
    include elasticsearch::nagios::plugin

    # some default configuration files conflict and should be removed
    file { '/etc/nagios-plugins/config/mailq.cfg':
        ensure => absent,
    }

}

