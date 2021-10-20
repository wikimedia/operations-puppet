# role to (ironically) apply on unpuppetized systems
#
class role::test {
    include ::profile::base::production
    include ::profile::base::firewall

    system::role { 'test': description => 'Unpuppetised system for testing' }
}
