# == Class: role::xhgui
#
# Aggregates XHProf profiling data from the app servers.
#
class role::xhgui {
    class { 'mongodb': }

    ferm::rule { 'xhgui_mongodb':
        rule => 'proto tcp dport 27017 { saddr $INTERNAL ACCEPT; }',
    }
}
