# == Class profile::hadoop::spark2
# Ensure that the WMF creaed spark2 package is installed,
# optionally Oozie has a spark2 sharelib.
# and optionally that the Spark 2 Yarn shuffle service is used.
#
# See also: https://docs.hortonworks.come/HDPDocuments/HDP2/HDP-2.6.0/bk_spark-component-guide/content/ch_oozie-spark-action.html#spark-config-oozie-spark2
#
# NOTE: This class is expected to be used on CDH based Hadoop installations, where
# spark 1 may also already be installed.
#
# [*install_yarn_shuffle_jar*]
#   If true, any Spark 1 yarn shuffle jars in /usr/lib/hadoop-yarn/lib will be replaced
#   With the Spark 2 one, causing YARN NodeManagers to run the Spark 2 shuffle service.
#   Default: true
#
# [*install_oozie_sharelib*]
#   If true, a Spark 2 oozie sharelib will be installed for the currently installed
#   Spark 2 version.  This only needs to happen once, so you should only
#   Set this to true on a single Hadoop client node (probably whichever one runs
#   Oozie server).
#
class profile::hadoop::spark2(
    $install_yarn_shuffle_jar = hiera('profile::hadoop::spark2::install_yarn_shuffle_jar', true),
    $install_oozie_sharelib   = hiera('profile::hadoop::spark2::install_oozie_sharelib', false),
) {
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


    # If we want to override any Spark 1 yarn shuffle service to run Spark 2 instead.
    if $install_yarn_shuffle_jar {
        # Add Spark 2 spark-yarn-shuffle.jar to the Hadoop Yarn NodeManager classpath.
        file { '/usr/local/bin/spark2_yarn_shuffle_jar_install':
            source  => 'puppet:///modules/profile/hadoop/spark2_yarn_shuffle_jar_install.sh',
            mode    => '0744',
            require => Package['spark2'],
        }
        exec { 'spark2_yarn_shuffle_jar_install':
            command => '/usr/local/bin/spark2_yarn_shuffle_jar_install',
            user    => 'root',
            # spark2_yarn_shuffle_jar_install will exit 0 if the current installed
            # version of spark2 has a yarn shuffle jar installed already.
            unless  => '/usr/local/bin/spark2_yarn_shuffle_jar_install',
            require => File['/usr/local/bin/spark2_yarn_shuffle_jar_install'],
        }
    }

    # If running on an oozie server, we can build and install a spark2
    # sharelib in HDFS so that oozie actions can launch spark2 jobs.
    if $install_oozie_sharelib {
        file { '/usr/local/bin/spark2_oozie_sharelib_install':
            source  => 'puppet:///modules/profile/hadoop/spark2_oozie_sharelib_install.sh',
            owner   => 'oozie',
            group   => 'root',
            mode    => '0744',
            require => [Class['::profile::oozie::server'], Package['spark2']],
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
