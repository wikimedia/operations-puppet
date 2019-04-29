# role to (ironically) apply on unpuppetized systems
#
# filtertags: labs-project-puppet
class role::test {
    include ::profile::standard
    include ::profile::base::firewall

    system::role { 'test': description => 'Unpuppetised system for testing' }
}
