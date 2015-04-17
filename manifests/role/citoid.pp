# vim: set ts=4 et sw=4:
class role::citoid {

    system::role { 'role::citoid': }

    ferm::service { 'citoid':
        proto => 'tcp',
        port  => '1970',
    }
    include ::citoid
}
