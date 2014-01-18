# vim: set sw=4 ts=4 expandtab:

# == Class: role::beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class role::beta::autoupdater {

    include beta::autoupdater

    system::role { 'role::beta':
        description => 'Server is autoupdating MediaWiki core and extension on beta.'
    }

}

class role::beta::natfix {

    system::role { 'role::beta::natfix':
        description => 'Server has beta NAT fixup'
    }

    include beta::natfix
}

class role::beta::maintenance {
    class{ 'misc::maintenance::geodata': enabled => true }
}
