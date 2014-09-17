# = Class: toollabs::monitoring::graphite
# Sets up graphite based icinga checks for all of toollabs
class toollabs::monitoring::graphite {
    monitor_graphite_threshold { 'toollabs-puppet-fail':
        description     => 'ToolLabs: Puppet failure events',
        metric          => 'tools.*.puppetagent.failed_events.value',
        critical        => 1,
        warning         => 1,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }

    monitor_graphite_threshold { 'toollabs-puppet-stale':
        description     => 'ToolLabs: Puppet freshness check',
        metric          => 'tools.*.puppetagent.time_since_last_run.value',
        warning         => 3600, # 1h
        critical        => 43200, # 12h
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }

    monitor_graphite_threshold { 'toollabs-low-space-var':
        description     => 'ToolLabs: Low disk space on /var',
        metric          => 'tools.*.diskspace._var.byte_avail.value',
        warning         => 67108864, # 512MiB
        critical        => 33554432, # 256MiB,
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }

    monitor_graphite_threshold { 'toollabs-low-space-root':
        description     => 'ToolLabs: Low disk space on /',
        metric          => 'tools.*.diskspace.root.byte_avail.value',
        warning         => 67108864, # 512MiB
        critical        => 33554432, # 256MiB,
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }

    monitor_graphite_threshold { 'toollabs-cpu-iowait':
        description     => 'ToolLabs: Excess CPU check: iowait',
        metric          => 'tools.*.cpu.total.iowait.value',
        warning         => 95,
        critical        => 99,
        percentage      => 100,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }

    monitor_graphite_threshold { 'toollabs-cpu-user':
        description     => 'ToolLabs: Excess CPU check: user',
        metric          => 'tools.*.cpu.total.user.value',
        warning         => 95,
        critical        => 99,
        percentage      => 100,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }

    monitor_graphite_threshold { 'toollabs-cpu-system':
        description     => 'ToolLabs: Excess CPU check: system',
        metric          => 'tools.*.cpu.total.system.value',
        warning         => 95,
        critical        => 99,
        percentage      => 100,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'toollabs',
        series          => true,
    }
}
