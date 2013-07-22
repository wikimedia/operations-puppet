class role::rsync {
    sysctl::parameters { 'high bandwidth rsync':
        values => {
            'vm.min_free_kbytes' => 262144,
        },
    }
}
