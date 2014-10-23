# gridengine::collectors::queues

define gridengine::collectors::queues($store, $config)
{

    gridengine::collector { $title:
        dir       => 'queues',
        sourcedir => $store,
        config    => template($config),
        require   => File[$store],
    }

}
