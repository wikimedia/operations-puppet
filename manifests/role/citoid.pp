# vim: set ts=4 et sw=4:
class role::citoid {

    system::role { 'role::citoid': }

    include ::citoid
}
