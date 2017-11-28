# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep
class role::apertium {
    system::role { 'apertium':
        description => 'Apertium APY server'
    }
    include ::profile::apertium
}
