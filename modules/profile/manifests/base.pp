# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure base config
# @param remote_syslog_tls Central TLS enabled syslog servers
# @param remote_syslog_tls_client_auth TLS client authentication enabled for remote syslog
# @param remote_syslog_tls_server_auth mode used to verify the authenticity of the syslog server
# @param remote_syslog_tls_netstream_driver rsyslog network stream driver to use
# for TLS in remote syslog, either 'gtls' (default)  or 'ossl'
# @param remote_syslog_tls_ca CA used for TLS, defaults to puppet CA
# @param remote_syslog_send_logs config for send logs
# @param overlayfs if to use overlays
# @param wikimedia_clusters the wikimedia clusters
# @param cluster the cluster
# @param enable_contacts use the contacts module
# @param core_dump_pattern the core dump pattern
# @param unprivileged_userns_clone enable kernel.unprivileged_userns_clone
# @param use_linux510_on_buster whether to setup kernel 5.10 on buster hosts
# @param additional_purged_packages A list of additional packages to purge
# @param manage_resolvconf set this to false to disable managing resolv.conf
#   useful in container environments
class profile::base (
    Hash                                $wikimedia_clusters                 = lookup('wikimedia_clusters'),
    String                              $cluster                            = lookup('cluster'),
    String                              $remote_syslog_send_logs            = lookup('profile::base::remote_syslog_send_logs'),
    Boolean                             $overlayfs                          = lookup('profile::base::overlayfs'),
    Boolean                             $enable_contacts                    = lookup('profile::base::enable_contacts'),
    String                              $core_dump_pattern                  = lookup('profile::base::core_dump_pattern'),
    Boolean                             $unprivileged_userns_clone          = lookup('profile::base::unprivileged_userns_clone'),
    Hash                                $remote_syslog_tls                  = lookup('profile::base::remote_syslog_tls'),
    Boolean                             $remote_syslog_tls_client_auth      = lookup('profile::base::remote_syslog_tls_client_auth'),
    Enum['x509/certvalid', 'x509/name'] $remote_syslog_tls_server_auth      = lookup('profile::base::remote_syslog_tls_server_auth', {'default_value' => 'x509/certvalid'}),
    Enum['gtls', 'ossl']                $remote_syslog_tls_netstream_driver = lookup('profile::base::remote_syslog_tls_netstream_driver', {'default_value' => 'gtls'}),
    Stdlib::Unixpath                    $remote_syslog_tls_ca               = lookup('profile::base::remote_syslog_tls_ca', {'default_value' => '/var/lib/puppet/ssl/certs/ca.pem'}),
    Boolean                             $use_linux510_on_buster             = lookup('profile::base::use_linux510_on_buster', {'default_value' => false}),
    Boolean                             $remove_python2_on_bullseye         = lookup('profile::base::remove_python2_on_bullseye', {'default_value' => true}),
    Boolean                             $manage_resolvconf                  = lookup('profile::base::manage_resolvconf', {'default_value' => true}),
    Boolean                             $manage_timesyncd                   = lookup('profile::base::manage_timesyncd', {'default_value' => true}),
    Array[String[1]]                    $additional_purged_packages          = lookup('profile::base::additional_purged_packages'),
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

    include profile::adduser
    contain profile::puppet::agent
    contain profile::base::certificates
    include profile::apt
    if !$facts['wmflib']['is_container'] and $manage_resolvconf {
        include profile::systemd::timesyncd
    }
    unless $facts['wmflib']['is_container']  {
        class { 'grub::defaults': }
    }

    if $use_linux510_on_buster {
        include profile::base::linux510
    }

    include passwords::root
    include network::constants
    if $manage_resolvconf {
        include profile::resolving
    }
    include profile::mail::default_mail_relay

    include profile::logrotate
    include profile::prometheus::node_exporter
    include profile::rsyslog
    include profile::prometheus::rsyslog_exporter
    include profile::prometheus::cadvisor

    $remote_syslog_tls_servers = $remote_syslog_tls[$::site]

    unless empty($remote_syslog_tls_servers) {
        class { 'base::remote_syslog':
            enable               => true,
            central_hosts_tls    => $remote_syslog_tls_servers,
            send_logs            => $remote_syslog_send_logs,
            tls_client_auth      => $remote_syslog_tls_client_auth,
            tls_server_auth      => $remote_syslog_tls_server_auth,
            tls_netstream_driver => $remote_syslog_tls_netstream_driver,
            tls_trusted_ca       => $remote_syslog_tls_ca,
        }
    }

    if !$facts['wmflib']['is_container'] {
        # TODO: make base::sysctl a profile itself?
        class { 'base::sysctl':
            unprivileged_userns_clone => $unprivileged_userns_clone,
        }
    }
    class { 'motd': }
    # Indicate if any services need to be restarted
    motd::script { 'Check for restarts':
        priority => 99,
        source   => 'puppet:///modules/profile/motd/check_restarts.sh',
    }
    class { 'base::standard_packages':
        remove_python2             => $remove_python2_on_bullseye,
        additional_purged_packages => $additional_purged_packages,
    }

    include profile::environment
    class { 'base::sysctl::core_dumps':
        core_dump_pattern => $core_dump_pattern,
    }

    include profile::ssh::client
    include profile::ssh::server

    if !$facts['wmflib']['is_container'] {
        class { 'base::kernel':
            overlayfs => $overlayfs,
        }
    }

    include profile::debdeploy::client

    class { 'base::initramfs': }
    include profile::auto_restarts

    class { 'prometheus::node_debian_version': }

    if $facts['is_virtual'] and debian::codename::lt('buster') and $facts['virtual'] != 'lxc' {
        class { 'haveged': }
    }
}
