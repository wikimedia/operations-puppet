# vim: set ts=2 sw=2 et :
# misc/icinga.pp

class icinga::user {
  include nagios::group
  # where does the dialout user group come from? it should be included here somehow

  user { 'icinga':
    name       => 'icinga',
    home       => '/home/icinga',
    gid        => 'icinga',
    system     => true,
    managehome => false,
    shell      => "/bin/false",
    require    => [ Group['dialout'], Group['nagios'] ],
    groups     => [ 'dialout', 'nagios' ]
  }
}

class icinga::monitor {

  include icinga::user,
    icinga::monitor::packages,
    passwords::nagios::mysql,
    icinga::monitor::firewall,
    icinga::monitor::configuration::files,
    icinga::monitor::files::nagios-plugins,
    icinga::monitor::snmp,
    icinga::monitor::checkpaging,
    icinga::monitor::service,
    icinga::monitor::jobqueue,
    icinga::monitor::snmp,
    icinga::monitor::naggen,
    icinga::monitor::nsca::daemon,
    icinga::monitor::apache,
    icinga::monitor::files::misc,
#    icinga::ganglia::ganglios,
    facilities::pdu_monitoring,
    lvs::monitor,
    nagios::gsbmonitoring,
    mysql,
    nrpe

  Class['icinga::monitor::packages'] -> Class['icinga::monitor::configuration::files'] -> Class['icinga::monitor::service']

}

# Nagios/icinga configuration files

class icinga::monitor::configuration::variables {

  #This variable declares the monitoring hosts
  #It is called master hosts as monitor_host is already
  #a service.

  $master_hosts = [ 'neon.wikimedia.org', 'spence.wikimedia.org' ]

  $icinga_config_dir = '/etc/icinga'
  $nagios_config_dir = '/etc/nagios'

  # puppet_hosts.cfg must be first
  $puppet_files = [
    "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_hostgroups.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_servicegroups.cfg"]

  $static_files = [
    "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_hostextinfo.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_services.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/icinga.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/analytics.cfg", # TEMP.  This will be removed when analytics puppetization goes to production
    "${icinga::monitor::configuration::variables::icinga_config_dir}/cgi.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/checkcommands.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/contactgroups.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/contacts.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/misccommands.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/resource.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/timeperiods.cfg",
    "${icinga::monitor::configuration::variables::icinga_config_dir}/htpasswd.users"]

}
class icinga::monitor::apache {
  class {'webserver::php5': ssl => true;}

  include webserver::php5-gd

        include passwords::ldap::wmf_cluster
        $proxypass = $passwords::ldap::wmf_cluster::proxypass

  file {
    '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
      source => 'puppet:///files/icinga/ubuntu.png',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    # install the icinga Apache site
    '/etc/apache2/sites-available/icinga.wikimedia.org':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      content => template('apache/sites/icinga.wikimedia.org.erb');
  }

    # remove icinga default config
  file {
    '/etc/icinga/apache2.conf':
      ensure => absent;
    '/etc/apache2/conf.d/icinga.conf':
      ensure => absent;
  }

  apache_site { 'icinga': name => 'icinga.wikimedia.org' }
  install_certificate{ 'star.wikimedia.org': }

}

class icinga::monitor::checkpaging {

  require icinga::monitor::packages

  file {'/usr/lib/nagios/plugins/check_to_check_nagios_paging':
    source => 'puppet:///files/icinga/check_to_check_nagios_paging',
    owner  => 'root',
    group  => 'root',
    mode   => '0755';
  }
  monitor_service { 'check_to_check_nagios_paging':
    description => 'check_to_check_nagios_paging',
    check_command => 'check_to_check_nagios_paging',
    normal_check_interval => 1,
    retry_check_interval => 1,
    contact_group => 'pager_testing',
    critical => false
  }
}

class icinga::monitor::configuration::files {
  # For all files dealing with icinga configuration

  require icinga::monitor::packages
  require passwords::nagios::mysql

  $nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

  Class['icinga::monitor::configuration::variables'] -> Class['icinga::monitor::configuration::files']

  # Icinga configuration files

  file { '/etc/icinga/cgi.cfg':
      source => 'puppet:///files/icinga/cgi.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/icinga.cfg':
      source => 'puppet:///files/icinga/icinga.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/nsca_payments.cfg':
      source => 'puppet:///private/nagios/nsca_payments.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/htpasswd.users':
      source => 'puppet:///private/nagios/htpasswd.users',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    # TEMP: analytics eqiad cluster manual entries.
    # This has been removed since analytics cluster
    # udp2log instances are now puppetized.
    '/etc/icinga/analytics.cfg':
      ensure  => 'absent';

    '/etc/icinga/checkcommands.cfg':
      content => template('icinga/checkcommands.cfg.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644';

    '/etc/icinga/contactgroups.cfg':
      source => 'puppet:///files/icinga/contactgroups.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/contacts.cfg':
      source => 'puppet:///private/nagios/contacts.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/misccommands.cfg':
      source => 'puppet:///files/icinga/misccommands.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/resource.cfg':
      source => 'puppet:///files/icinga/resource.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/icinga/timeperiods.cfg':
      source => 'puppet:///files/icinga/timeperiods.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/init.d/icinga':
      source => 'puppet:///files/icinga/icinga-init',
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
  }
}

class icinga::monitor::files::misc {
# Required files and directories
# Must be loaded last

  file {
    '/etc/icinga/conf.d':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';

    '/etc/nagios':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';

    '/var/cache/icinga':
      ensure => directory,
      owner  => 'icinga',
      group  => 'www-data',
      mode   => '0775';

    '/var/lib/nagios/rw':
      ensure => directory,
      owner  => 'icinga',
      group  => 'nagios',
      mode   => '0777';

    '/var/lib/icinga':
      ensure => directory,
      owner  => 'icinga',
      group  => 'www-data',
      mode   => '0755';

    # Script to purge resources for non-existent hosts
     '/usr/local/sbin/purge-nagios-resources.py':
      source => 'puppet:///files/icinga/purge-nagios-resources.py',
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
  }

  # fix permissions on all individual service files
  exec {
    'fix_nagios_perms':
      command => '/bin/chmod -R a+r /etc/nagios';

    'fix_icinga_perms':
      command => '/bin/chmod -R a+r /etc/icinga';

    'fix_icinga_temp_files':
      command => '/bin/chown -R icinga /var/lib/icinga';

    'fix_nagios_plugins_files':
      command => '/bin/chmod -R a+w /var/lib/nagios';

    'fix_icinga_command_file':
      command => '/bin/chmod a+rw /var/lib/nagios/rw/nagios.cmd';
  }
}

class icinga::monitor::files::nagios-plugins {

  require icinga::monitor::packages

  file {
    '/usr/lib/nagios':
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';

    '/usr/lib/nagios/plugins':
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';

    '/usr/lib/nagios/plugins/eventhandlers':
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';

    '/usr/lib/nagios/plugins/eventhandlers/submit_check_result':
      source => 'puppet:///files/icinga/submit_check_result',
      owner => 'root',
      group => 'root',
      mode => '0755';

    '/var/lib/nagios/rm':
      ensure => directory,
      owner => icinga,
      group => nagios,
      mode => '0775';

    '/etc/nagios-plugins':
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';

    '/etc/nagios-plugins/config':
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';

    '/etc/nagios-plugins/config/apt.cfg':
      source => 'puppet:///files/icinga/plugin-config/apt.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/breeze.cfg':
      source => 'puppet:///files/icinga/plugin-config/breeze.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/dhcp.cfg':
      source => 'puppet:///files/icinga/plugin-config/dhcp.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/disk-smb.cfg':
      source => 'puppet:///files/icinga/plugin-config/disk-smb.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/disk.cfg':
      source => 'puppet:///files/icinga/plugin-config/disk.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/dns.cfg':
      source => 'puppet:///files/icinga/plugin-config/dns.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/dummy.cfg':
      source => 'puppet:///files/icinga/plugin-config/dummy.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/flexlm.cfg':
      source => 'puppet:///files/icinga/plugin-config/flexlm.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/ftp.cfg':
      source => 'puppet:///files/icinga/plugin-config/ftp.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/hppjd.cfg':
      source => 'puppet:///files/icinga/plugin-config/hppjd.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/http.cfg':
      source => 'puppet:///files/icinga/plugin-config/http.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/ifstatus.cfg':
      source => 'puppet:///files/icinga/plugin-config/ifstatus.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/ldap.cfg':
      source => 'puppet:///files/icinga/plugin-config/ldap.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/load.cfg':
      source => 'puppet:///files/icinga/plugin-config/load.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/mail.cfg':
      source => 'puppet:///files/icinga/plugin-config/mail.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/mrtg.cfg':
      source => 'puppet:///files/icinga/plugin-config/mrtg.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/mysql.cfg':
      source => 'puppet:///files/icinga/plugin-config/mysql.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/netware.cfg':
      source => 'puppet:///files/icinga/plugin-config/netware.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/news.cfg':
      source => 'puppet:///files/icinga/plugin-config/news.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/nt.cfg':
      source => 'puppet:///files/icinga/plugin-config/nt.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/ntp.cfg':
      source => 'puppet:///files/icinga/plugin-config/ntp.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/pgsql.cfg':
      source => 'puppet:///files/icinga/plugin-config/pgsql.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/ping.cfg':
      source => 'puppet:///files/icinga/plugin-config/ping.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/procs.cfg':
      source => 'puppet:///files/icinga/plugin-config/procs.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/radius.cfg':
      source => 'puppet:///files/icinga/plugin-config/radius.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/real.cfg':
      source => 'puppet:///files/icinga/plugin-config/real.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/rpc-nfs.cfg':
      source => 'puppet:///files/icinga/plugin-config/rpc-nfs.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/snmp.cfg':
      source => 'puppet:///files/icinga/plugin-config/snmp.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/ssh.cfg':
      source => 'puppet:///files/icinga/plugin-config/ssh.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/tcp_udp.cfg':
      source => 'puppet:///files/icinga/plugin-config/tcp_udp.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/telnet.cfg':
      source => 'puppet:///files/icinga/plugin-config/telnet.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/users.cfg':
      source => 'puppet:///files/icinga/plugin-config/users.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';

    '/etc/nagios-plugins/config/vsz.cfg':
      source => 'puppet:///files/icinga/plugin-config/vsz.cfg',
      owner => 'root',
      group => 'root',
      mode => '0644';
  }

  # WMF custom service checks
  file {
    '/usr/lib/nagios/plugins/check_mysql-replication.pl':
      source => 'puppet:///files/icinga/check_mysql-replication.pl',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_cert':
      owner => 'root',
      group => 'root',
      mode => '0755',
      source => 'puppet:///files/icinga/check_cert';
    '/usr/lib/nagios/plugins/check_all_memcached.php':
      source => 'puppet:///files/icinga/check_all_memcached.php',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_bad_apaches':
      source => 'puppet:///files/icinga/check_bad_apaches',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_longqueries':
      source => 'puppet:///files/icinga/check_longqueries',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_MySQL.php':
      source => 'puppet:///files/icinga/check_MySQL.php',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_solr':
      source => 'puppet:///files/icinga/check_solr',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check-ssl-cert':
      source => 'puppet:///files/icinga/check-ssl-cert',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_stomp.pl':
      source => 'puppet:///files/icinga/check_stomp.pl',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_nrpe':
      source => 'puppet:///files/icinga/check_nrpe',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/lib/nagios/plugins/check_ram.sh':
      source => 'puppet:///files/icinga/check_ram.sh',
      owner => 'root',
      group => 'root',
      mode => '0755';
  }

  # some default configuration files conflict and should be removed

  file {
    '/etc/nagios-plugins/config/mailq.cfg':
      ensure => absent;
  }

}


class icinga::monitor::firewall {

  # deny access to port 5667 TCP (nsca) from external networks
  # deny service snmp-trap (port 162) for external networks

  class iptables-purges {

    require 'iptables::tables'
    iptables_purge_service{  'deny_pub_snmptrap': service => 'snmptrap' }
    iptables_purge_service{  'deny_pub_nsca': service => 'nsca' }
  }

  class iptables-accepts {

    require 'icinga::monitor::firewall::iptables-purges'

    iptables_add_service{ 'lo_all': interface => 'lo', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'localhost_all': source => '127.0.0.1', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_pmtpa_nolabs': source => '10.0.0.0/14', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_esams': source => '10.21.0.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_eqiad1': source => '10.64.0.0/17', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_eqiad2': source => '10.65.0.0/20', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_virt': source => '10.4.16.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_152': source => '208.80.152.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_153': source => '208.80.153.128/26', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_154': source => '208.80.154.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_fundraising': source => '208.80.155.0/27', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_esams': source => '91.198.174.0/25', service => 'all', jump => 'ACCEPT' }
  }

  class iptables-drops {

    require 'icinga::monitor::firewall::iptables-accepts'
    iptables_add_service{ 'deny_pub_nsca': service => 'nsca', jump => 'DROP' }
    iptables_add_service{ 'deny_pub_snmptrap': service => 'snmptrap', jump => 'DROP' }
    iptables_add_service{ 'TEMP_deny_smtp': service => 'smtp', jump => 'DROP' }
  }

  class iptables {

    require 'icinga::monitor::firewall::iptables-drops'
    iptables_add_exec{ "${hostname}_nsca": service => 'nsca' }
    iptables_add_exec{ "${hostname}_snmptrap": service => 'snmptrap' }
  }

  require 'icinga::monitor::firewall::iptables'
}

class icinga::monitor::jobqueue {
  include icinga::monitor::packages
  include applicationserver::packages

  file {'/usr/lib/nagios/plugins/check_job_queue':
    source => 'puppet:///files/icinga/check_job_queue',
    owner => 'root',
    group => 'root',
    mode => '0755';
  }

  monitor_service { 'check_job_queue':
    description => 'check_job_queue',
    check_command => 'check_job_queue',
    normal_check_interval => 15,
    retry_check_interval => 5,
    critical => false
  }
}

class icinga::monitor::naggen {

  # Naggen takes exported resources from hosts and creates nagios configuration files

  require icinga::monitor::packages

  file {
    '/etc/icinga/puppet_hosts.cfg':
      content => generate('/usr/local/bin/naggen', '--stdout', '--type', 'host'),
      backup => false,
      owner => 'root',
      group => 'root',
      mode => '0644';
    '/etc/icinga/puppet_services.cfg':
      content => generate('/usr/local/bin/naggen', '--stdout', '--type', 'service'),
      backup => false,
      owner => 'root',
      group => 'root',
      mode => '0644';
    '/etc/icinga/puppet_hostextinfo.cfg':
      content => generate('/usr/local/bin/naggen', '--stdout', '--type', 'hostextinfo'),
      backup => false,
      owner => 'root',
      group => 'root',
      mode => '0644';
  }

  # Fix permissions

  file { $icinga::monitor::configuration::variables::puppet_files:
    ensure => present,
    mode   => '0644';
  }

    # Collect all (virtual) resources
  Monitor_group <| |> {
    notify => Service[icinga],
  }
  Monitor_host <| |> {
    notify => Service[icinga],
  }
  Monitor_service <| tag != 'nrpe' |> {
    notify => Service[icinga],
  }

  # Decommission servers
  decommission_monitor_host { $decommissioned_servers: }
}

# NSCA - Nagios Service Check Acceptor
# package contains daemon and client script
class icinga::nsca {

  package { 'nsca':
    ensure => latest;
  }

}

# NSCA - daemon config
class icinga::monitor::nsca::daemon {

  system_role { 'icinga::nsca::daemon': description => 'Nagios Service Checks Acceptor Daemon' }

  require icinga::nsca

  file { '/etc/nsca.cfg':
    source => 'puppet:///private/icinga/nsca.cfg',
    owner => 'root',
    mode => '0400';
  }

  service { 'nsca':
    ensure => running;
  }
}

class icinga::monitor::packages {

  # icinga: icinga itself
  # icinga-doc: files for the web-frontend

  package { [ 'icinga', 'icinga-doc' ]:
    ensure => latest;
  }

  # Stomp Perl module to monitor erzurumi (RT #703)
  package { 'libnet-stomp-perl':
    ensure => latest;
  }
}

class icinga::monitor::service {

  require icinga::monitor::apache

  service { 'icinga':
    ensure => running,
    hasstatus => false,
    subscribe => [
      File[$icinga::monitor::configuration::variables::puppet_files],
      File[$icinga::monitor::configuration::variables::static_files],
      File['/etc/icinga/puppet_services.cfg'],
      File['/etc/icinga/puppet_hostextinfo.cfg'],
      File['/etc/icinga/puppet_hosts.cfg']];
  }
}

class icinga::monitor::snmp {

  file {
    '/etc/snmp/snmptrapd.conf':
      source => 'puppet:///files/snmp/snmptrapd.conf.icinga',
      owner => 'root',
      group => 'root',
      mode => '0600';
    '/etc/snmp/snmptt.conf':
      source => 'puppet:///files/snmp/snmptt.conf.icinga',
      owner => 'root',
      group => 'root',
      mode => '0644';
    '/etc/init.d/snmptt':
      source => 'puppet:///files/snmp/snmptt.init',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/etc/init.d/snmptrapd':
      source => 'puppet:///files/snmp/snmptrapd.init',
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/etc/init.d/snmpd':
      source => 'puppet:///files/snmp/snmpd.init',
      owner => 'root',
      group => 'root',
      mode => '0755';
  }

  # snmp tarp stuff
  systemuser { 'snmptt': name => 'snmptt', home => '/var/spool/snmptt', groups => [ 'snmptt', 'nagios' ] }

  package { 'snmpd':
    ensure => latest;
  }

  package { 'snmptt':
    ensure => latest;
  }

  service { 'snmptt':
    ensure => running,
    hasstatus => false,
    hasrestart => true,
    subscribe => [
      File['/etc/snmp/snmptt.conf'],
      File['/etc/init.d/snmptt'],
      File['/etc/snmp/snmptrapd.conf']];
  }

  service { 'snmptrapd':
    ensure => running,
    hasstatus => false,
    subscribe => [
      File['/etc/init.d/snmptrapd'],
      File['/etc/snmp/snmptrapd.conf']];
  }

  service { 'snmpd':
    ensure => running,
    hasstatus => false,
    subscribe => File['/etc/init.d/snmpd'];
  }

  # FIXME: smptt crashes periodically on precise
  cron { 'restart_snmptt':
    ensure => present,
    command => 'service snmptt restart 2>&1',
    user => root,
    hour => [0, 4, 8, 12, 16, 20],
    minute => 7;
  }

}

class icinga::ganglia::ganglios {
  include ganglia::collector

  package { 'ganglios':
    ensure => latest;
  }
  cron { 'ganglios-cron':
    ensure => present,
    command => 'test -w /var/log/ganglia/ganglia_parser.log && /usr/sbin/ganglia_parser',
    user => icinga,
    minute => '*/2';
  }
  file { '/var/lib/ganglia/xmlcache':
    ensure => directory,
    mode => '0755',
    owner => icinga;
  }
}

# Used to be called nagios::ganglia::monitor::enwiki
class misc::monitoring::enwikijobqueue {

	include passwords::nagios::mysql
	require mysql_wmf::client
	$ganglia_mysql_enwiki_pass = $passwords::nagios::mysql::mysql_enwiki_pass
	$ganglia_mysql_enwiki_user = $passwords::nagios::mysql::mysql_enwiki_user
	# Password is actually the same for all clusters and wikis, not en.wiki only
	cron {
		enwiki_jobqueue_length:
			command => "/usr/bin/gmetric --name='enwiki JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --value=$(mysql --batch --skip-column-names -u $ganglia_mysql_enwiki_user -p$ganglia_mysql_enwiki_pass -h db36.pmtpa.wmnet enwiki -e 'select count(*) from job') > /dev/null 2>&1",
			user => root,
			ensure => present;
	}
	# duplicating the above job to experiment with gmetric's host spoofing so as to
	#  gather these metrics in a fake host called "en.wikipedia.org"
	cron {
		enwiki_jobqueue_length_spoofed:
			command => "/usr/bin/gmetric --name='enwiki JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --spoof 'en.wikipedia.org:en.wikipedia.org' --value=$(mysql --batch --skip-column-names -u $ganglia_mysql_enwiki_user -p$ganglia_mysql_enwiki_pass -h db36.pmtpa.wmnet enwiki -e 'select count(*) from job') > /dev/null 2>&1",
			user => root,
			ensure => present;
	}
}

# global monitoring groups - formerly misc/nagios.pp

@monitor_group { 'misc_eqiad': description => 'eqiad misc servers' }
@monitor_group { 'misc_pmtpa': description => 'pmtpa misc servers' }
