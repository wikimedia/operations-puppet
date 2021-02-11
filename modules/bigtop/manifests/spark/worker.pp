# == Class bigtop::spark::worker
#
class bigtop::spark::worker {
    Class['bigtop::spark'] -> Class['bigtop::spark::worker']

    # Fail if not running spark in standalone mode
    if !$bigtop::spark::standalone_enabled {
        fail('Do not include bigtop::spark::worker unless $bigtop::spark::master_host is set and you intend to run Spark in standalone mode (not YARN).')
    }

    package { 'spark-worker':
        ensure => 'installed',
    }

    service { 'spark-worker':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['spark-worker'],
    }
}
