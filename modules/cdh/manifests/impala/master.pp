# == Class cdh::impala::master
# Installs impala master services.
# This assumes you want to run state-store, catalog, and llama on the same node.
# This does not yet support HA llama.
#
class cdh::impala::master inherits cdh::impala {
    package {[
        'impala-state-store',
        'impala-catalog',
        'llama-master',
    ]:
        ensure => 'installed',
    }

    service { 'impala-state-store':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['impala-state-store'],
    }

    service { 'impala-catalog':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['impala-catalog'],
    }

    service { 'llama':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['llama-master'],
    }
}

