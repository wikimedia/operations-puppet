# == Class profile::alluxio::common
# Installs alluxio with settings common to both masters and workers
#
class profile::alluxio::common(
    Hash[String, Any] $zookeeper_clusters = lookup('zookeeper_clusters'),
    Hash[String, Any] $alluxio_services   = lookup('alluxio_services'),
    Hash[String, Any] $config_override    = lookup('profile::alluxio::common::config_override', { 'default_value' => {} }),
    String $alluxio_service_name          = lookup('profile::alluxio::common::alluxio_service_name'),
    String $alluxio_zookeeper_cluster     = lookup('profile::alluxio::common::zookeeper_cluster')

) {
    require ::profile::hadoop::common

    # The final alluxio configuration is merged from three sources.
    # 1) 'alluxio_global_config' is common to all hadoop clusters but varies from the default or undefined
    # 2) 'alluxio_service_name' is particular to a given hadoop cluster, but may be shared between several roles
    # 3) 'config_override' is overridden at the role or host level
    #
    # Every element of the resulting hash should correspond to a property from the reference list here:
    # https://docs.alluxio.io/os/user/2.4/en/reference/Properties-List.html
    #
    # Six categories of property are described on that list and they are structured as sub-hashes here to aid
    # clarity in the resulting alluxio-site.properties configuration file.
    $alluxio_global_config = {
        common_properties => {
            'alluxio.underfs.hdfs.configuration' => '/etc/hadoop/conf/core-site.xml:/etc/hadoop/conf/hdfs-site.xml',
            'alluxio.zookeeper.enabled'          => true,
        },
        security_properties => {
            'alluxio.security.authorization.permission.enabled' => true,
            'alluxio.security.login.impersonation.username'     => '_HDFS_USER_',
        },
        master_properties => {
            'alluxio.master.keytab.file'                                                                       => '/etc/security/keytabs/alluxio/alluxio.keytab',
            'alluxio.master.principal'                                                                         =>  "alluxio/${::fqdn}@WIKIMEDIA",
            'alluxio.master.journal.type'                                                                      => 'UFS',
            'alluxio.master.mount.table.root.option.alluxio.security.underfs.hdfs.kerberos.client.principal'   => "alluxio/${::fqdn}@WIKIMEDIA",
            'alluxio.master.mount.table.root.option.alluxio.security.underfs.hdfs.kerberos.client.keytab.file' => '/etc/security/keytabs/alluxio/alluxio.keytab',
            'alluxio.master.mount.table.root.option.alluxio.security.underfs.hdfs.impersonation.enabled'       => true,
            'alluxio.master.security.impersonation.presto.users'                                               => '*',
        },
        worker_properties => {
            'alluxio.worker.keytab.file' => '/etc/security/keytabs/alluxio/alluxio.keytab',
            'alluxio.worker.principal'   => "alluxio/${::fqdn}@WIKIMEDIA"
        },
        user_properties => {},
        resource_manager_properties => {},
    }
    $alluxio_properties = deep_merge($alluxio_global_config,deep_merge($alluxio_services[$alluxio_service_name],$config_override))

    $zookeeper_hosts = $alluxio_zookeeper_cluster ? {
        undef   => undef,
        default => join(keys($zookeeper_clusters[$alluxio_zookeeper_cluster]['hosts']),','),
    }


    class { '::bigtop::alluxio':
      zookeeper_hosts    => $zookeeper_hosts,
      alluxio_properties => $alluxio_properties,
    }
}
