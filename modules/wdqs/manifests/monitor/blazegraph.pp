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

    # TODO: add monitoring of the http and https endpoints, and of the service
}
