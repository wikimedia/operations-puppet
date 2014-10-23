# gridengine::collectors::queues

define gridengine::collectors::queues($store, $config)
{

    gridengine::collector { $title:
        dir       => 'queues',
        sourcedir => $store,
        content   => template($config),
        require   => File[$store],
    }

}
