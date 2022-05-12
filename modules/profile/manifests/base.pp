# @summary profile to configure base config
# @param remote_syslog Central syslog servers
# @param remote_syslog_tls Central TLS enabled syslog servers
# @param remote_syslog_send_logs config for send logs
# @param ssh_server_settings ssh server config
# @param overlayfs if to use overlays
# @param wikimedia_clusters the wikimedia clusters
# @param cluster the cluster
# @param enable_contacts use the contacts module
# @param core_dump_pattern the core dump pattern
# @param manage_ssh_keys if we shold managed ssh keys
class profile::base(
    Hash    $wikimedia_clusters      = lookup('wikimedia_clusters'),
    String  $cluster                 = lookup('cluster'),
    String  $remote_syslog_send_logs = lookup('profile::base::remote_syslog_send_logs'),
    Boolean $overlayfs               = lookup('profile::base::overlayfs'),
    Boolean $enable_contacts         = lookup('profile::base::enable_contacts'),
    String  $core_dump_pattern       = lookup('profile::base::core_dump_pattern'),
    Boolean $manage_ssh_keys         = lookup('profile::base::manage_ssh_keys'),
    Array   $remote_syslog           = lookup('profile::base::remote_syslog'),
    Hash    $remote_syslog_tls       = lookup('profile::base::remote_syslog_tls'),
    Hash    $ssh_server_settings     = lookup('profile::base::ssh_server_settings'),
) {
    # Sanity checks for cluster - T234232
    if ! has_key($wikimedia_clusters, $cluster) {
        fail("Cluster ${cluster} not defined in wikimedia_clusters")
    }

    if ! has_key($wikimedia_clusters[$cluster]['sites'], $::site) {
        fail("Site ${::site} not found in cluster ${cluster}")
    }

    # create standard directories
    # perform this here and early to avoid dependency cycles
    file { ['/usr/local/sbin', '/usr/local/share/bash']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    contain profile::base::puppet
    contain profile::base::certificates
    include profile::apt
    include profile::systemd::timesyncd
    class { 'adduser': }

    class { 'grub::defaults': }

    include passwords::root
    include network::constants
    include profile::resolving
    include profile::mail::default_mail_relay

    include profile::prometheus::node_exporter
    class { 'rsyslog': }
    include profile::prometheus::rsyslog_exporter

    $remote_syslog_tls_servers = $remote_syslog_tls[$::site]

    unless empty($remote_syslog) and empty($remote_syslog_tls_servers) {
        class { 'base::remote_syslog':
            enable            => true,
            central_hosts     => $remote_syslog,
            central_hosts_tls => $remote_syslog_tls_servers,
            send_logs         => $remote_syslog_send_logs,
        }
    }

    # TODO: make base::sysctl a profile itself?
    class { 'base::sysctl': }
    class { 'motd': }
    class { 'base::standard_packages': }
    Class['profile::apt'] -> Class['base::standard_packages']
    include profile::environment
    class { 'base::sysctl::core_dumps':
        core_dump_pattern => $core_dump_pattern,
    }

    class { 'ssh::client':
        manage_ssh_keys => $manage_ssh_keys,
    }

    # # TODO: create profile::ssh::server
    # Ssh server default settings are good for most installs, but some overrides
    # might be needed
    class {'ssh::server':
        * => $ssh_server_settings,
    }

    class { 'base::kernel':
        overlayfs => $overlayfs,
    }

    include profile::debdeploy::client

    class { 'base::initramfs': }
    include profile::auto_restarts

    class { 'prometheus::node_debian_version': }

    if $facts['is_virtual'] and debian::codename::le('buster') {
        class {'haveged': }
    }
}
