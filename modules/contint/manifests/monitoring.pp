# = Class: contint::monitoring::graphite
# Sets up graphite based icinga checks for all of integration
class contint::monitoring::graphite {
    monitor_graphite_threshold { 'contint-puppet-fail':
        description     => 'CI: Puppet failure events',
        metric          => 'integration.*.puppetagent.failed_events.value',
        critical        => 1,
        warning         => 1,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-puppet-stale':
        description     => 'CI: Puppet freshness check',
        metric          => 'integration.*.puppetagent.time_since_last_run.value',
        warning         => 3600, # 1h
        critical        => 43200, # 12h
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-low-space-var':
        description     => 'CI: Low disk space on /var',
        metric          => 'integration.*.diskspace._var.byte_avail.value',
        warning         => 67108864, # 512MiB
        critical        => 33554432, # 256MiB,
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-low-space-mnt':
        description     => 'CI: Low disk space on /mnt',
        metric          => 'integration.*.diskspace._mnt.byte_avail.value',
        warning         => 17179869184, # 16GiB
        critical        => 1073741824, # 1 GiB
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-low-space-root':
        description     => 'CI: Low disk space on /',
        metric          => 'integration.*.diskspace.root.byte_avail.value',
        warning         => 67108864, # 512MiB
        critical        => 33554432, # 256MiB,
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-cpu-iowait':
        description     => 'CI: Excess CPU check: iowait',
        metric          => 'integration.*.cpu.total.iowait.value',
        warning         => 90,
        critical        => 97,
        percentage      => 100,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-cpu-user':
        description     => 'CI: Excess CPU check: user',
        metric          => 'integration.*.cpu.total.user.value',
        warning         => 90,
        critical        => 97,
        percentage      => 100,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }

    monitor_graphite_threshold { 'contint-cpu-system':
        description     => 'CI: Excess CPU check: system',
        metric          => 'integration.*.cpu.total.system.value',
        warning         => 90,
        critical        => 97,
        percentage      => 100,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'contint',
        series          => true,
    }
}
