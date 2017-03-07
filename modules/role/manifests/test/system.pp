# role to (ironically) apply on unpuppetized systems
#
# filtertags: labs-project-puppet
class role::test::system {
    include ::standard
    include ::base::firewall

    system::role { 'role::test::system': description => 'Unpuppetised system for testing' }
}
