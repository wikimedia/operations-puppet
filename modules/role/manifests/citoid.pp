# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep
class role::citoid {

    system::role { 'role::citoid': }

    include ::citoid
}
