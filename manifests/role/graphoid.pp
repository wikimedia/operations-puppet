# vim: set ts=4 et sw=4:
class role::graphoid {

    system::role { 'role::graphoid': }

    ferm::service { 'graphoid':
        proto => 'tcp',
        port  => '19000',
    }

    include ::graphoid

}
