# SPDX-License-Identifier: Apache-2.0
#
# == Class profile::conftool::client
#
# Configures a server to be a conftool client, setting up
#
# - The etcd client configuration in /etc/etcd/etcdrc
# - The conftool client configuration
# - The etcd credentials for the root user in /root/.etcdrc
#
# === Parameters
# @srv_domain The srv domain to query to get the etcd cluster servers
# @conftool_prefix the prefix that conftool uses for its keys
# @tcpircbot_host the host to contact for tcpircbot
# @tcpircbot_port the port to contact tcpircbot on
# @etcd_host the host to contact for etcd, to use in alternative to the srv domain
# @etcd_port the port for the etcd server, to use in alternative to the srv domain
# @pool_pwd_seed the secret seed for generating password for automatic users
# @etcd_user the etcd user to install the credentials for under /root/.etcdrc.
#    Defaults to '__auto__', which will try to autogenerate the password.
# @conftool2git_address the address of the conftool2git server, if any
#
class profile::conftool::client (
    Stdlib::Host           $srv_domain             = lookup('etcd_client_srv_domain'),
    Stdlib::Unixpath       $namespace              = lookup('conftool_prefix').dirname(),
    Stdlib::Host           $tcpircbot_host         = lookup('tcpircbot_host'),
    Stdlib::Port           $tcpircbot_port         = lookup('tcpircbot_port'),
    Optional[Stdlib::Host] $host                   = lookup('etcd_host', { 'default_value' => undef }),
    Optional[Stdlib::Port] $port                   = lookup('etcd_port', { 'default_value' => undef }),
    String                 $pool_pwd_seed          = lookup('etcd::autogen_pwd_seed'),
    String                 $etcd_user              = lookup('profile::conftool::client::etcd_user', { 'default_value' => '__auto__' }),
    Stdlib::Fqdn           $conftool2git_host      = lookup('profile::conftool2git::active_host', { 'default_value' => '' }),
    String                 $conftool2git_bind_addr = lookup('profile::conftool2git::address', { 'default_value' => '0.0.0.0:1312' }),
) {
    ensure_packages(['python3-conftool'])

    require passwords::etcd

    # This is the configuration shared by all users.
    class { 'etcd::client::globalconfig':
        srv_domain => $srv_domain,
        host       => $host,
        port       => $port,
    }

    if $etcd_user != '__auto__' {
        $user = $etcd_user
        $pwd = $passwords::etcd::accounts[$etcd_user]
        $conftool_cluster = undef
    } else {
        # When autogenerating the password, use conftool as a fallback if we're not in a LVS cluster.
        $user = 'conftool'
        $pwd = $passwords::etcd::accounts['conftool']
        # determine which conftool cluster we're part of, if any.
        $module_path = get_module_path('profile')
        $site_nodes = loadyaml("${module_path}/../../conftool-data/node/${::site}.yaml")[$::site]
        $conftool_clusters = $site_nodes.filter |$cl, $pools| {
            $facts['networking']['fqdn'] in $pools.keys()
        }
        .map |$cl, $pools| { $cl }.unique()
        # if we found one and only one cluster, install the cluster-site specifc credentials
        if $conftool_clusters.length() == 1 {
            $conftool_cluster = $conftool_clusters[0]
        } else {
            $conftool_cluster = undef
        }
    }

    # This is the configuration for the user root will access.
    etcd::client::config { '/root/.etcdrc':
        settings => conftool::cluster_credentials($user, $pwd, $pool_pwd_seed, $conftool_cluster),
    }

    if $conftool2git_host != '' {
        $parsed_addr = split($conftool2git_bind_addr, /:/)
        $conftool2git_address = "${conftool2git_host}:${parsed_addr[1]}"
    } else {
        $conftool2git_address = ''
    }

    class { 'conftool::config':
        namespace            => $namespace,
        tcpircbot_host       => $tcpircbot_host,
        tcpircbot_port       => $tcpircbot_port,
        hosts                => [],
        conftool2git_address => $conftool2git_address,
    }

    # Conftool schema. Let's assume we will only have one.
    file { '/etc/conftool/schema.yaml':
        ensure => file,
        source => 'puppet:///modules/profile/conftool/schema.yaml',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # json schemas container
    file { '/etc/conftool/json-schema/':
        ensure  => directory,
        source  => 'puppet:///modules/profile/conftool/json-schema/',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        recurse => true,
    }
}
