# == Class: role::mwprof
#
# Sets up mwprof.
#
class role::mwprof {
    system::role { 'role::mwprof': description => 'MediaWiki profiler', }
    package { [ 'build-essential', 'libdb-dev' ]: }
    deployment::target { 'mwprof': }
}
