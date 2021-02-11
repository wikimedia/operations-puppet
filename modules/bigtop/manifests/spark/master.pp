# == Class bigtop::spark::master
# Sets up a standalone spark master.
# NOTE:  This class should not be used if you are running Spark
# in YARN mode, which is the recommended and default way to use
# Spark in CDH.  Only use this if you are setting up a standalone
# spark cluster.
class bigtop::spark::master {
    Class['bigtop::spark'] -> Class['bigtop::spark::master']

    # Fail if not running spark in standalone mode
    if !$bigtop::spark::standalone_enabled {
        fail('Do not include bigtop::spark::master unless $bigtop::spark::master_host is set and you intend to run Spark in standalone mode (not YARN).')
    }

    package { 'spark-master':
        ensure => 'installed'
    }

    service { 'spark-master':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['spark-master'],
    }
}
