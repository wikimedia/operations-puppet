# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hive::metastore
# Configures hive-metastore.
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hive_metastore_configure.html
#
# == Parameters
# $port       - Port on which hive-metastore listens.  Default: undef
#
class bigtop::hive::metastore(
    $port             = undef,
)
{
    Class['bigtop::hive'] -> Class['bigtop::hive::metastore']

    package { 'hive-metastore':
        ensure => 'installed',
    }

    # If the metastore will use MySQL for storage, then
    # we need to make sure the Mysql/Mariadb JDBC .jar is
    # in hive-metastore's classpath before it launches.
    if $::bigtop::hive::jdbc_protocol == 'mysql' {
        include bigtop::hive::metastore::mysql::jar
        Class['bigtop::hive::metastore::mysql::jar'] -> Service['hive-metastore']
    }

    service { 'hive-metastore':
        ensure     => 'running',
        require    => [
            Package['hive-metastore'],
        ],
        hasrestart => true,
        hasstatus  => true,
    }
}