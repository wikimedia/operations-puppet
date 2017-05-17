# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep
class role::mathoid{
    system::role { 'mathoid':
        description => 'mathoid server'
    }

    include ::mathoid
}
