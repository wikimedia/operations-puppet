# == Class cdh::hive::metastore
# Configures hive-metastore.
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hive_metastore_configure.html
#
# == Parameters
# $port       - Port on which hive-metastore listens.  Default: undef
#
class cdh::hive::metastore(
    $port             = undef,
)
{
    Class['cdh::hive'] -> Class['cdh::hive::metastore']

    package { 'hive-metastore':
        ensure => 'installed',
    }

    # If the metastore will use MySQL for storage, then
    # we need to make sure the libmysql-java .jar is in
    # hive-metastore's classpath before it launches.
    if $::cdh::hive::jdbc_protocol == 'mysql' {
        include cdh::hive::metastore::mysql::jar
        Class['cdh::hive::metastore::mysql::jar'] -> Service['hive-metastore']
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