# == Class: wdqs::monitor::blazegraph
#
# Create diamond monitoring for Blazegraph
#
class wdqs::monitor::blazegraph {
    diamond::collector { 'Blazegraph':
        settings => {
            counters => '"/Query Engine/queryDoneCount", "/Query Engine/queryErrorCount", "/Query Engine/queriesPerSecond"'
        },
        source => 'puppet:///modules/wdqs/BlazegraphCollector.py',
        custom_name => 'blazegraphstats',
    }
}

