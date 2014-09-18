# = Class: beta::monitoring::graphite
# Sets up graphite based icinga checks for all of betalabs
class beta::monitoring::graphite {
    monitor_graphite_threshold { 'betalabs-puppet-fail':
        from            => '10min',
        description     => 'BetaLabs: Puppet failure events',
        metric          => 'deployment-prep.*.puppetagent.failed_events.value',
        critical        => 1,
        warning         => 1,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'betalabs',
        series          => true,
    }

    monitor_graphite_threshold { 'betalabs-puppet-stale':
        description     => 'BetaLabs: Puppet freshness check',
        metric          => 'deployment-prep.*.puppetagent.time_since_last_run.value',
        warning         => 3600, # 1h
        critical        => 43200, # 12h
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'betalabs',
        series          => true,
    }

    monitor_graphite_threshold { 'betalabs-low-space-var':
        description     => 'BetaLabs: Low disk space on /var',
        metric          => 'deployment-prep.*.diskspace._var.byte_avail.value',
        warning         => 67108864, # 512MiB
        critical        => 33554432, # 256MiB,
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'betalabs',
        series          => true,
    }

    monitor_graphite_threshold { 'betalabs-low-space-root':
        description     => 'BetaLabs: Low disk space on /',
        metric          => 'deployment-prep.*.diskspace.root.byte_avail.value',
        warning         => 67108864, # 512MiB
        critical        => 33554432, # 256MiB,
        under           => true,
        graphite_url    => 'http://labmon1001.eqiad.wmnet',
        contact_group   => 'betalabs',
        series          => true,
    }
}

