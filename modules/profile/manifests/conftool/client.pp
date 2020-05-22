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
#
class profile::conftool::client(
    Stdlib::Host           $srv_domain     = lookup('etcd_client_srv_domain'),
    Stdlib::Unixpath       $namespace      = dirname(lookup('conftool_prefix')),
    Stdlib::Host           $tcpircbot_host = lookup('tcpircbot_host'),
    Stdlib::Port           $tcpircbot_port = lookup('tcpircbot_port'),
    Optional[Stdlib::Host] $host           = lookup('etcd_host', {'default_value' => undef}),
    Optional[Stdlib::Port] $port           = lookup('etcd_port', {'default_value' => undef}),
    String                 $pool_pwd_seed  = lookup('etcd::autogen_pwd_seed'),
    Boolean                $allow_root     = lookup('profile::conftool::client::allow_root', {'default_value' => true})
) {

    if os_version('debian >= stretch') {
        $socks_pkg = 'python-socks'
    } else {
        $socks_pkg = 'python-pysocks'
    }

    $conftool_pkg = 'python3-conftool'

    require_package(
        $conftool_pkg,
        $socks_pkg,
    )

    require ::passwords::etcd

    # This is the configuration shared by all users.
    class { '::etcd::client::globalconfig':
        srv_domain => $srv_domain,
        host       => $host,
        port       => $port,
    }

    if $allow_root {
        $user = 'root'
        $pwd = $::passwords::etcd::accounts['root']
        $conftool_cluster = undef
    } else {
        $user = 'conftool'
        $pwd = $::passwords::etcd::accounts['conftool']
        # determine which conftool cluster we're part of, if any.
        $module_path = get_module_path('profile')
        $site_nodes = loadyaml("${module_path}/../../conftool-data/node/${::site}.yaml")[$::site]
        $conftool_clusters = $site_nodes.filter |$cl, $pools| {
            $::fqdn in $pools.keys()
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
    ::etcd::client::config { '/root/.etcdrc':
        settings => conftool::cluster_credentials($user, $pwd, $pool_pwd_seed, $conftool_cluster)
    }

    class  { '::conftool::config':
        namespace      => $namespace,
        tcpircbot_host => $tcpircbot_host,
        tcpircbot_port => $tcpircbot_port,
        hosts          => [],
    }

    # Conftool schema. Let's assume we will only have one.
    file { '/etc/conftool/schema.yaml':
        ensure => present,
        source => 'puppet:///modules/profile/conftool/schema.yaml',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # json schemas container
    file {'/etc/conftool/json-schema/':
        ensure  => directory,
        source  => 'puppet:///modules/profile/conftool/json-schema/',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        recurse => true,
    }
}
