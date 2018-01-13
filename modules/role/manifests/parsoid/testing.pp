# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {
    system::role { 'parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    include ::profile::parsoid::testing
}
