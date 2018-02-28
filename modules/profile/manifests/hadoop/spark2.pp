# == Class profile::hadoop::spark2
# Ensure that the WMF creaed spark2 package is installed,
# and that Oozie has a spark2 sharelib.
# See also: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.0/bk_spark-component-guide/content/ch_oozie-spark-action.html#spark-config-oozie-spark2
class profile::hadoop::spark2 {
    require ::profile::hadoop::common

    # The deb package creates as post-install step a symlink like
    # /etc/spark/conf/hive-site.xml -> /etc/hive/conf.analytics/hive-site.xml
    # This package needs to be installed after the deploy of the Hive configuration.
    # (should be guaranteed by the puppet evaluation order).
    if defined(Class['::profile::hive::client']) {
        Class['::profile::hive::client'] -> Class['::profile::hadoop::spark2']
    }

    package { 'spark2':
        ensure => 'present',
    }

    # If running on an oozie server, we can build and install a spark2
    # sharelib in HDFS so that oozie actions can launch spark2 jobs.
    if defined(Class['::profile::oozie::server']) {
        Class['::profile::oozie::server'] -> Class['::profile::hadoop::spark2']

        file { '/usr/local/bin/spark2_oozie_sharelib_install':
            source  => 'puppet:///modules/profile/hadoop/spark2_oozie_sharelib_install',
            owner   => 'oozie',
            group   => 'root',
            mode    => '0744',
            require => Package['spark2'],
        }

        exec { 'spark2_oozie_sharelib_install':
            command => '/usr/local/bin/spark2_oozie_sharelib_install',
            user    => 'oozie',
            # spark2_oozie_sharelib_install will exit 0 if the current installed
            # version of spark2 has a oozie sharelib installed already.
            unless  => '/usr/local/bin/spark2_oozie_sharelib_install',
            require => File['/usr/local/bin/spark2_oozie_sharelib_install'],
        }
    }
}
