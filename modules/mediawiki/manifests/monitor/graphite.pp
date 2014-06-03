# Class defining all icinga checks on graphite that only run on aggregates.
# If you want to define a check that runs on each appserver, just define it in
# the corresponding class directly.
class mediawiki::monitor::graphite {

    # check the incoming job queue length for anomalies
    monitor_graphite_anomaly { 'mediawiki_jobs_queued':
        description  => 'Number of mediawiki jobs queued',
        metric       => 'MediaWiki.stats.job-insert.count',
        warning      => 5,
        critical     => 10,
        check_window => 100,
    }

    # Also check that the metric is being collected
    monitor_graphite_threshold { 'mediawiki_jobs_queued_above_0':
        description     => 'More than 0 jobs queued',
        metric          => 'MediaWiki.stats.job-insert.count',
        from            => '1hours',
        warning         => 1,
        critical        => 0,
        under           => true,
        nagios_critical => false
        # this will be enabled shortly if we don't see false positives
    }

    # check the running jobs length for anomalies
    monitor_graphite_anomaly { 'mediawiki_jobs_running':
        description  => 'Number of mediawiki jobs running',
        metric       => 'MediaWiki.stats.job-pop.count',
        warning      => 5,
        critical     => 10,
        check_window => 100,
    }

    # Also check that the metric is being collected
    monitor_graphite_threshold { 'mediawiki_jobs_running_above_0':
        description     => 'More than 0 jobs running',
        metric          => 'MediaWiki.stats.job-pop.count',
        from            => '1hours',
        warning         => 1,
        critical        => 0,
        under           => true,
        nagios_critical => false
        # this will be enabled shortly if we don't see false positives
    }
}
