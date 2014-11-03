# Class defining all icinga checks on graphite that only run on aggregates.
# If you want to define a check that runs on each appserver, just define it in
# the corresponding class directly.
class mediawiki::monitoring::graphite {

    # Also check that the metric is being collected
    monitoring::graphite_threshold { 'mediawiki_jobs_queued_above_0':
        description     => 'More than 0 jobs queued',
        metric          => 'MediaWiki.stats.job-insert.count',
        from            => '1hours',
        warning         => 1,
        critical        => 0,
        under           => true,
        nagios_critical => false
        # this will be enabled shortly if we don't see false positives
    }

    # Also check that the metric is being collected
    monitoring::graphite_threshold { 'mediawiki_jobs_running_above_0':
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
