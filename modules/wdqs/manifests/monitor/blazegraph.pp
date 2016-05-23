# == Class: wdqs::monitor::blazegraph
#
# Create diamond monitoring for Blazegraph
#
class wdqs::monitor::blazegraph {
    require ::wdqs::service
    diamond::collector { 'Blazegraph':
        settings => {
            counters => [
                '"/Query Engine/queryStartCount"',
                '"/Query Engine/queryDoneCount"',
                '"/Query Engine/queryErrorCount"',
                '"/Query Engine/queriesPerSecond"',
                '"/Journal/bytesReadPerSec"',
                '"/Journal/bytesWrittenPerSec"',
                '"/Journal/extent"',
                '"/Journal/commitCount"',
                '"/Journal/commit/totalCommitSecs"',
                '"/Journal/commit/flushWriteSetSecs"',
                '"/JVM/Memory/DirectBufferPool/default/bytesUsed"',
                '"/JVM/Memory/Runtime Free Memory"',
                '"/JVM/Memory/Runtime Max Memory"',
                '"/JVM/Memory/Runtime Total Memory"',
            ],
        },
        source   => 'puppet:///modules/wdqs/monitor/blazegraph.py',
    }

    # raise a warning / critical alert if response time was over 2 minutes / 5 minutes
    # more than 5% of the time during the last minute
    monitoring::graphite_threshold { 'wdqs-response-time':
        description   => 'Response time of WDQS',
        metric        => "varnish.eqiad.backends.be_${::hostname}.GET.p99",
        warning       => 120000, # 2 minutes
        critical      => 300000, # 5 minutes
        from          => '10min',
        percentage    => 5,
        contact_group => 'wdqs-admins',
    }

    # TODO: add monitoring of the http and https endpoints, and of the service
}
