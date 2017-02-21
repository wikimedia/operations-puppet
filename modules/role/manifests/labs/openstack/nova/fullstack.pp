class role::labs::openstack::nova::fullstack {
    system::role { $name: }

    $novaconfig = hiera_hash('novaconfig', {})
    $fullstack_pass = $novaconfig['osstackcanary_pass']

    class { '::openstack::nova::fullstack':
        password => $fullstack_pass,
    }
}
