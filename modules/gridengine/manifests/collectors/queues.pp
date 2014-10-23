# gridengine::collectors::queues

define gridengine::collectors::queues($store, $config)
{

    file { $store:
        ensure    => directory,
        owner     => 'root',
        group     => 'root',
        mode      => '0755',
    }

    gridengine::collector { $title:
        dir       => 'queues',
        sourcedir => $store,
        content   => $config,
        require   => File[$store],
    }

}
