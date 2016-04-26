# role to (ironically) apply on unpuppetized systems
class role::test::system {
    include standard

    system::role { 'role::test::system': description => 'Unpuppetised system for testing' }
}
