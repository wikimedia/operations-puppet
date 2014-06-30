# vim: set ts=2 sw=2 et :
# misc/icinga.pp

class icinga::user {
    include nagios::group
    # FIXME: where does the dialout user group come from?
    # It should be included here somehow

    group { 'icinga':
        ensure => present,
        name   => 'icinga',
    }

    user { 'icinga':
        name       => 'icinga',
        home       => '/home/icinga',
        gid        => 'icinga',
        system     => true,
        managehome => false,
        shell      => '/bin/false',
        require    => [ Group['icinga'], Group['nagios'] ],
        groups     => [ 'dialout', 'nagios' ],
    }
}

class icinga::monitor {

    include facilities::pdu_monitoring
    include icinga::ganglia::check
    include icinga::ganglia::ganglios
    include icinga::monitor::apache
    include icinga::monitor::checkpaging
    include icinga::monitor::configuration::files
    include icinga::monitor::files::misc
    include icinga::monitor::files::nagios-plugins
    include icinga::monitor::firewall
    include icinga::monitor::logrotate
    include icinga::monitor::naggen
    include icinga::monitor::nsca::daemon
    include icinga::monitor::packages
    include icinga::monitor::service
    include icinga::monitor::wikidata
    include icinga::user
    include lvs::monitor
    include misc::dsh::files
    include mysql
    include nagios::gsbmonitoring
    include nrpe
    include passwords::nagios::mysql

    Class['icinga::monitor::packages'] -> Class['icinga::monitor::configuration::files'] -> Class['icinga::monitor::service']

}

# Nagios/icinga configuration files

class icinga::monitor::configuration::variables {

    # This variable declares the monitoring hosts It is called master hosts as
    # monitor_host is already a service.
    $master_hosts = [ 'neon.wikimedia.org' ]

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
        "${icinga::monitor::configuration::variables::icinga_config_dir}/timeperiods.cfg"]
}

class icinga::monitor::apache {
    class {'webserver::php5': ssl => true,}
    ferm::service { 'icinga-https':
      proto => 'tcp',
      port  => 443,
    }
    ferm::service { 'icinga-http':
      proto => 'tcp',
      port  => 80,
    }

    include webserver::php5-gd

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///files/icinga/ubuntu.png',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # install the Icinga Apache site
    apache::site { 'icinga.wikimedia.org':
        content => template('apache/sites/icinga.wikimedia.org.erb'),
    }

    # remove icinga default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga.conf':
        ensure => absent,
    }

    install_certificate{ 'icinga.wikimedia.org': ca => 'RapidSSL_CA.pem' }
    install_certificate{ 'icinga-admin.wikimedia.org': ca => 'RapidSSL_CA.pem' }

}

class icinga::monitor::checkpaging {

    require icinga::monitor::packages

    file {'/usr/lib/nagios/plugins/check_to_check_nagios_paging':
        source => 'puppet:///files/icinga/check_to_check_nagios_paging',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    monitor_service { 'check_to_check_nagios_paging':
        description           => 'check_to_check_nagios_paging',
        check_command         => 'check_to_check_nagios_paging',
        normal_check_interval => 1,
        retry_check_interval  => 1,
        contact_group         => 'pager_testing',
        critical              => false
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
        mode   => '0644',
    }

    file { '/etc/icinga/icinga.cfg':
        source => 'puppet:///files/icinga/icinga.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/nsca_frack.cfg':
        source => 'puppet:///private/nagios/nsca_frack.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # TEMP: analytics eqiad cluster manual entries.
    # This has been removed since analytics cluster
    # udp2log instances are now puppetized.
    file { '/etc/icinga/analytics.cfg':
        ensure  => 'absent',
    }

    file { '/etc/icinga/checkcommands.cfg':
        content => template('icinga/checkcommands.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/icinga/contactgroups.cfg':
        source => 'puppet:///files/icinga/contactgroups.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/contacts.cfg':
        source => 'puppet:///private/nagios/contacts.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/misccommands.cfg':
        source => 'puppet:///files/icinga/misccommands.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/resource.cfg':
        source => 'puppet:///files/icinga/resource.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/timeperiods.cfg':
        source => 'puppet:///files/icinga/timeperiods.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/init.d/icinga':
        source => 'puppet:///files/icinga/icinga-init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}

class icinga::monitor::files::misc {
# Required files and directories
# Must be loaded last

    file { '/etc/icinga/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/nagios':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/cache/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0775',
    }

    file { '/var/lib/nagios/rw':
        ensure => directory,
        owner  => 'icinga',
        group  => 'nagios',
        mode   => '0777',
    }

    file { '/var/lib/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0755',
    }

    # Script to purge resources for non-existent hosts
    file { '/usr/local/sbin/purge-nagios-resources.py':
        source => 'puppet:///files/icinga/purge-nagios-resources.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # fix permissions on all individual service files
    exec { 'fix_nagios_perms':
        command => '/bin/chmod -R a+r /etc/nagios';
    }
    exec { 'fix_icinga_perms':
        command => '/bin/chmod -R a+r /etc/icinga';
    }
    exec { 'fix_icinga_temp_files':
        command => '/bin/chown -R icinga /var/lib/icinga';
    }
    exec { 'fix_nagios_plugins_files':
        command => '/bin/chmod -R a+w /var/lib/nagios';
    }
    exec { 'fix_icinga_command_file':
        command => '/bin/chmod a+rw /var/lib/nagios/rw/nagios.cmd';
    }
    file { '/var/log/icinga':
        ensure => directory,
        owner => 'icinga',
        mode => '2757',
    }
    file { '/var/log/icinga/archives':
        ensure => directory,
        owner => 'icinga',
    }
    file { '/var/log/icinga/icinga.log':
        ensure => file,
        owner => 'icinga',
    }
}

class icinga::monitor::files::nagios-plugins {

    require icinga::monitor::packages

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
        source => 'puppet:///files/icinga/submit_check_result',
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
        source => 'puppet:///files/icinga/plugin-config/apt.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/breeze.cfg':
        source => 'puppet:///files/icinga/plugin-config/breeze.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/dhcp.cfg':
        source => 'puppet:///files/icinga/plugin-config/dhcp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/disk-smb.cfg':
        source => 'puppet:///files/icinga/plugin-config/disk-smb.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/disk.cfg':
        source => 'puppet:///files/icinga/plugin-config/disk.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/dns.cfg':
        source => 'puppet:///files/icinga/plugin-config/dns.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/dummy.cfg':
        source => 'puppet:///files/icinga/plugin-config/dummy.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/flexlm.cfg':
        source => 'puppet:///files/icinga/plugin-config/flexlm.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ftp.cfg':
        source => 'puppet:///files/icinga/plugin-config/ftp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/hppjd.cfg':
        source => 'puppet:///files/icinga/plugin-config/hppjd.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/http.cfg':
        source => 'puppet:///files/icinga/plugin-config/http.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ifstatus.cfg':
        source => 'puppet:///files/icinga/plugin-config/ifstatus.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ldap.cfg':
        source => 'puppet:///files/icinga/plugin-config/ldap.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/load.cfg':
        source => 'puppet:///files/icinga/plugin-config/load.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/mail.cfg':
        source => 'puppet:///files/icinga/plugin-config/mail.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/mrtg.cfg':
        source => 'puppet:///files/icinga/plugin-config/mrtg.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/mysql.cfg':
        source => 'puppet:///files/icinga/plugin-config/mysql.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/netware.cfg':
        source => 'puppet:///files/icinga/plugin-config/netware.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/news.cfg':
        source => 'puppet:///files/icinga/plugin-config/news.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/nt.cfg':
        source => 'puppet:///files/icinga/plugin-config/nt.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ntp.cfg':
        source => 'puppet:///files/icinga/plugin-config/ntp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/pgsql.cfg':
        source => 'puppet:///files/icinga/plugin-config/pgsql.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ping.cfg':
        source => 'puppet:///files/icinga/plugin-config/ping.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/procs.cfg':
        source => 'puppet:///files/icinga/plugin-config/procs.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/radius.cfg':
        source => 'puppet:///files/icinga/plugin-config/radius.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/real.cfg':
        source => 'puppet:///files/icinga/plugin-config/real.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/rpc-nfs.cfg':
        source => 'puppet:///files/icinga/plugin-config/rpc-nfs.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/snmp.cfg':
        source => 'puppet:///files/icinga/plugin-config/snmp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/ssh.cfg':
        source => 'puppet:///files/icinga/plugin-config/ssh.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/tcp_udp.cfg':
        source => 'puppet:///files/icinga/plugin-config/tcp_udp.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/telnet.cfg':
        source => 'puppet:///files/icinga/plugin-config/telnet.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/users.cfg':
        source => 'puppet:///files/icinga/plugin-config/users.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    file { '/etc/nagios-plugins/config/vsz.cfg':
        source => 'puppet:///files/icinga/plugin-config/vsz.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    File <| tag == nagiosplugin |>

    # WMF custom service checks
    file { '/usr/lib/nagios/plugins/check_mysql-replication.pl':
        source => 'puppet:///files/icinga/check_mysql-replication.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_cert':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///files/icinga/check_cert',
    }
    file { '/usr/lib/nagios/plugins/check_all_memcached.php':
        source => 'puppet:///files/icinga/check_all_memcached.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_dsh_groups':
        source => 'puppet:///files/icinga/check_dsh_groups',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_longqueries':
        source => 'puppet:///files/icinga/check_longqueries',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_MySQL.php':
        source => 'puppet:///files/icinga/check_MySQL.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_solr':
        source => 'puppet:///files/icinga/check_solr',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_ssl_cert':
        source => 'puppet:///files/icinga/check_ssl_cert/check_ssl_cert',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_nrpe':
        source => 'puppet:///files/icinga/check_nrpe',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_ram.sh':
        source => 'puppet:///files/icinga/check_ram.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_graphite':
        source => 'puppet:///files/icinga/check_graphite',
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

class icinga::monitor::firewall {
    # ncsa on port 5667
    ferm::rule { 'ncsa_allowed':
        rule => 'saddr (127.0.0.1 $EQIAD_PRIVATE_ANALYTICS1_A_EQIAD $EQIAD_PRIVATE_ANALYTICS1_B_EQIAD $EQIAD_PRIVATE_ANALYTICS1_C_EQIAD $EQIAD_PRIVATE_ANALYTICS1_D_EQIAD $EQIAD_PRIVATE_LABS_HOSTS1_A_EQIAD $EQIAD_PRIVATE_LABS_HOSTS1_B_EQIAD $EQIAD_PRIVATE_LABS_HOSTS1_D_EQIAD $EQIAD_PRIVATE_LABS_SUPPORT1_C_EQIAD $EQIAD_PRIVATE_PRIVATE1_A_EQIAD $EQIAD_PRIVATE_PRIVATE1_B_EQIAD $EQIAD_PRIVATE_PRIVATE1_C_EQIAD $EQIAD_PRIVATE_PRIVATE1_D_EQIAD $EQIAD_PUBLIC_PUBLIC1_A_EQIAD $EQIAD_PUBLIC_PUBLIC1_B_EQIAD $EQIAD_PUBLIC_PUBLIC1_C_EQIAD $EQIAD_PUBLIC_PUBLIC1_D_EQIAD $ESAMS_PRIVATE_PRIVATE1_ESAMS $ESAMS_PUBLIC_PUBLIC_SERVICES $PMTPA_PRIVATE_PRIVATE $PMTPA_PRIVATE_VIRT_HOSTS $PMTPA_PUBLIC_PUBLIC_SERVICES $PMTPA_PUBLIC_PUBLIC_SERVICES_2 $PMTPA_PUBLIC_SANDBOX $PMTPA_PUBLIC_SQUID_LVS $ULSFO_PRIVATE_PRIVATE1_ULSFO $ULSFO_PUBLIC_PUBLIC1_ULSFO 208.80.155.0/27 10.64.40.0/24) proto tcp dport 5667 ACCEPT;'
    }
}

class icinga::monitor::naggen {

    # Naggen takes exported resources from hosts and creates nagios
    # configuration files

    require icinga::monitor::packages

    file { '/etc/icinga/puppet_hosts.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'hosts'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
    file { '/etc/icinga/puppet_services.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'services'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
    file { '/etc/icinga/puppet_hostextinfo.cfg':
        content => generate('/usr/local/bin/naggen2', '--type', 'hostextinfo'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # Fix permissions

    file { $icinga::monitor::configuration::variables::puppet_files:
        ensure => present,
        mode   => '0644',
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

}

# NSCA - Nagios Service Check Acceptor
# NSCA - daemon config
class icinga::monitor::nsca::daemon {

    system::role { 'icinga::nsca::daemon': description => 'Nagios Service Checks Acceptor Daemon' }

    package { 'nsca':
        ensure => latest,
    }

    file { '/etc/nsca.cfg':
        source  => 'puppet:///private/icinga/nsca.cfg',
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca'],
    }

    service { 'nsca':
        ensure  => running,
        require => File['/etc/nsca.cfg'],
    }
}

# NSCA - client config
class icinga::monitor::nsca::client {
    package { 'nsca-client':
        ensure => 'installed',
    }

    file { '/etc/send_nsca.cfg':
        source  => 'puppet:///private/icinga/send_nsca.cfg',
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca-client'],
    }
}

class icinga::monitor::packages {

    # icinga: icinga itself
    # icinga-doc: files for the web-frontend

    package { [ 'icinga', 'icinga-doc' ]:
        ensure => latest,
    }

}

class icinga::monitor::service {

    require icinga::monitor::apache

    file { '/var/icinga-tmpfs':
        ensure => directory,
        owner => 'icinga',
        group => 'icinga',
        mode => '0755',
    }

    mount { '/var/icinga-tmpfs':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'tmpfs',
        device  => 'none',
        options => 'size=128m,uid=icinga,gid=icinga,mode=755',
        require => File['/var/icinga-tmpfs']
    }

    service { 'icinga':
        ensure    => running,
        hasstatus => false,
        restart   => '/etc/init.d/icinga reload',
        subscribe => [
            File[$icinga::monitor::configuration::variables::puppet_files],
            File[$icinga::monitor::configuration::variables::static_files],
            File['/etc/icinga/puppet_services.cfg'],
            File['/etc/icinga/puppet_hostextinfo.cfg'],
            File['/etc/icinga/puppet_hosts.cfg'],
        ],
        require => Mount['/var/icinga-tmpfs'],
    }
}

class icinga::ganglia::ganglios {
    include ganglia::collector::config

    package { 'ganglios':
        ensure => 'installed',
    }

    cron { 'ganglios-cron':
        ensure  => present,
        command => 'test -w /var/log/ganglia/ganglia_parser.log && /usr/sbin/ganglia_parser',
        user    => 'icinga',
        minute  => '*/2',
    }

    file { '/var/lib/ganglia/xmlcache':
        ensure => directory,
        mode   => '0755',
        owner  => 'icinga',
    }

}

class icinga::monitor::wikidata {

    @monitor_host { 'wikidata':
        ip_address => '91.198.174.192',
    }

    file { '/usr/local/lib/nagios/plugins/check_wikidata':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///files/icinga/check_wikidata',
    }

    monitor_service { 'wikidata.org dispatch lag':
        description   => 'check if wikidata.org dispatch lag is higher than 2 minutes',
        check_command => 'check_wikidata',
        host          => 'wikidata',
        normal_check_interval => 30,
        retry_check_interval => 5,
        contact_group => 'admins,wikidata',
    }
}

# == Class icinga::ganglia::check
#
# Installs check_ganglia package and sets up symlink into
# /usr/lib/nagios/plugins.
#
# check_ganglia allows arbitrary values to be queried from ganglia and checked
# for nagios/icinga.  This is better than ganglios, as it queries gmetad's xml
# query interfaces directly, rather than downloading and mangling xmlfiles from
# each aggregator.
#
class icinga::ganglia::check {
    package { 'check-ganglia':
        ensure  => 'installed',
    }

    file { '/usr/lib/nagios/plugins/check_ganglia':
        ensure  => 'link',
        target  => '/usr/bin/check_ganglia',
        require => Package['check-ganglia'],
    }
}

class icinga::monitor::logrotate {
    file { '/etc/logrotate.d/icinga':
        ensure => present,
        source => 'puppet:///files/logrotate/icinga',
        mode   => '0444',
    }
}

# global monitoring groups - formerly misc/nagios.pp

@monitor_group { 'misc_eqiad': description => 'eqiad misc servers' }
@monitor_group { 'misc_pmtpa': description => 'pmtpa misc servers' }
@monitor_group { 'misc_codfw': description => 'codfw misc servers' }
@monitor_group { 'misc_esams': description => 'esams misc servers' }
@monitor_group { 'misc_ulsfo': description => 'ulsfo misc servers' }
# This needs to be consolited in the virt cluster probably
@monitor_group { 'labsnfs_eqiad': description => 'eqiad labsnfs server servers' }
