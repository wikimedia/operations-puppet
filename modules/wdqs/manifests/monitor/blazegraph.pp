# == Class: wdqs::monitor::blazegraph
#
# Create diamond monitoring for Blazegraph
#
class wdqs::monitor::blazegraph {
    require ::wdqs::service

    require_package('python-dateutil')

    diamond::collector { 'Blazegraph':
        settings => {
            counters => [
                '"/Query Engine/queryStartCount"',
                '"/Query Engine/queryDoneCount"',
                '"/Query Engine/queryErrorCount"',
                '"/Query Engine/queriesPerSecond"',
                '"/Query Engine/GeoSpatial/geoSpatialSearchRequests"',
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
                '"/JVM/Memory/Garbage Collectors/G1 Old Generation/Collection Count"',
                '"/JVM/Memory/Garbage Collectors/G1 Old Generation/Cumulative Collection Time"',
                '"/JVM/Memory/Garbage Collectors/G1 Young Generation/Collection Count"',
                '"/JVM/Memory/Garbage Collectors/G1 Young Generation/Cumulative Collection Time"',
            ],
        },
        source   => 'puppet:///modules/wdqs/monitor/blazegraph.py',
        require  => Package['python-dateutil'],
    }

    # TODO: add monitoring of the http and https endpoints, and of the service
}
