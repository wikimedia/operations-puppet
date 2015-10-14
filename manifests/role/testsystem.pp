class role::testsystem {
    include standard

    system::role { 'role::testsystem': description => 'Unpuppetised system for testing' }
}
