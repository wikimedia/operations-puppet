# == Class authdns::monitoring
# Monitoring checks for authdns, specific to Wikimedia setup
#

# This monitors the specific authdns server directly via
#  its own fqdn, which won't generally be one of the listener
#  addresses we really care about.  This gives a more-direct
#  view of reality, though, as the mapping of listener addresses
#  to real hosts could be fluid due to routing/anycast.
class authdns::monitoring {
    monitoring::service { 'auth dns':
        description   => 'Auth DNS',
        check_command => 'check_dns!www.wikipedia.org',
    }
}
