# systctl config for grid nodes.
#
class profile::toolforge::grid::sysctl {
    sysctl::parameters { 'toolforge':
        values => {
            'vm.overcommit_memory' => 2,
            'vm.overcommit_ratio'  => 95,
        },
    }
}