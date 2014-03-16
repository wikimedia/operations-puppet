# == Class: role::mwprof
#
# Sets up mwprof, a MediaWiki profiling log collector.
#
class mwprof::reporter {
    deployment::target { 'mwprof/reporter': }
}
