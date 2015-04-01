# == Define: diamond::collector::conntrack
#
# Collect connection tracking statistics from host; mostly useful in
# routers but potentially valuable anywhere iptables are used to stateful
# filtering.
#
define diamond::collector::conntrack {

    diamond::collector { 'Conntrack':
        source  => 'puppet:///modules/diamond/collector/conntrack.py',
    }

}
