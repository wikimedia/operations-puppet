# Class defining all icinga checks on graphite that only run on aggregates.
# If you want to define a check that runs on each appserver, just define it in
# the corresponding class directly.
class mediawiki::monitoring::graphite {

    # Also check that the metric is being collected
    monitoring::graphite_threshold { 'mediawiki_job_insert_rate':
        description     => 'MediaWiki jobs not being inserted',
        metric          => 'MediaWiki.jobqueue.inserts.all.rate',
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
        metric          => 'MediaWiki.jobqueue.pops.all.rate',
        from            => '1hours',
        warning         => 1,
        critical        => 0,
        under           => true,
        nagios_critical => false
        # this will be enabled shortly if we don't see false positives
    }

    # MediaWiki is reporting edit failures due to session loss
    monitoring::graphite_threshold { 'mediawiki_failure_session_loss':
        description     => 'MediaWiki edit failures due to session loss',
        metric          => 'MediaWiki.edit.failures.session_loss.count',
        from            => '15min',
        warning         => 30,
        critical        => 50,
        percentage      => 70,
    }

    # MediaWiki is reporting edit failures due to bad token
    monitoring::graphite_threshold { 'mediawiki_failure_bad_token':
        description     => 'MediaWiki edit failures due to bad token',
        metric          => 'MediaWiki.edit.failures.bad_token.count',
        from            => '15min',
        warning         => 30,
        critical        => 50,
        percentage      => 70,
    }
}
