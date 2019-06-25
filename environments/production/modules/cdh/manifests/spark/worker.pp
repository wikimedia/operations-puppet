# == Class cdh::spark::worker
#
class cdh::spark::worker {
    Class['cdh::spark'] -> Class['cdh::spark::worker']

    # Fail if not running spark in standalone mode
    if !$cdh::spark::standalone_enabled {
        fail('Do not include cdh::spark::worker unless $cdh::spark::master_host is set and you intend to run Spark in standalone mode (not YARN).')
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
