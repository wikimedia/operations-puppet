# == Class druid::cdh::hadoop::dependencies
# Installs hadoop-dependencies for druid by symlinking to
# cdh installed directories.  This works for both
# hadoop-client and for the druid-hdfs-storage extension.
#
class druid::cdh::hadoop::dependencies {
    Class['cdh::hadoop']    -> Class['druid::cdh::hadoop::dependencies']
    Package['druid-common'] -> Class['druid::cdh::hadoop::dependencies']

    # Symlink the cdh provided hadoop client directory into druid's
    # hadoop-dependencies/hadoop-client.  To use this version in your
    # jobs, you need to set:
    # "hadoopDependencyCoordinates": ["org.apache.hadoop:hadoop-client:cdh"].
    file { '/usr/share/druid/hadoop-dependencies/hadoop-client/cdh':
        ensure => 'link',
        target => '/usr/lib/hadoop/client',
    }

    # druid-hdfs-storage is shipped with Hadoop 2.3.0 jars.  We need a
    # new extension called druid-hdfs-storage-cdh which symlinks to
    # the installed cdh jars, but still includes the
    # druid-hdfs-storage .jar.
    # Install a script that will do this for us.
    file { '/usr/local/bin/druid-hdfs-storage-cdh-link':
        source => 'puppet:///modules/druid/druid-hdfs-storage-cdh-link.sh',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }

    # Run the druid-hdfs-storage-cdh-link to create a
    # new extension using CDH jars.
    exec { 'create-druid-hdfs-storaage-cdh-extension':
        command => '/usr/local/bin/druid-hdfs-storage-cdh-link',
        creates => '/usr/share/druid/extensions/druid-hdfs-storage-cdh',
        require => File['/usr/local/bin/druid-hdfs-storage-cdh-link'],
    }
}
