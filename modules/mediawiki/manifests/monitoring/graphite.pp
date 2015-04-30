# Class defining all icinga checks on graphite that only run on aggregates.
# If you want to define a check that runs on each appserver, just define it in
# the corresponding class directly.
class mediawiki::monitoring::graphite {

    # Also check that the metric is being collected
    monitoring::graphite_threshold { 'mediawiki_job_insert_rate':
        description     => 'MediaWiki jobs not being inserted',
        metric          => 'MediaWiki.job-insert.rate',
        from            => '1hours',
        warning         => 1,
        critical        => 0,
        under           => true,
        nagios_critical => false
        # this will be enabled shortly if we don't see false positives
    }

    # Also check that the metric is being collected
    monitoring::graphite_threshold { 'mediawiki_job_pop_rate':
        description     => 'MediaWiki jobs not dequeued',
        metric          => 'MediaWiki.job-pop.rate',
        from            => '1hours',
        warning         => 1,
        critical        => 0,
        under           => true,
        nagios_critical => false
        # this will be enabled shortly if we don't see false positives
    }
}
