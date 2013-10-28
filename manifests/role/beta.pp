# vim: set sw=4 ts=4 expandtab:

# == Class: role::beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class role::beta::autoupdater {

    include misc::beta::autoupdater

    system::role { 'role::beta::autoupdater':
        description => 'Server is autoupdating MediaWiki core and extension on beta.'
    }

}

class role::beta::maintenance {
    class{ 'misc::maintenance::geodata': enabled => true }
}
