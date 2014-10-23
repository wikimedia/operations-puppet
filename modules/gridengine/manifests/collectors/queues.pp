# gridengine::collectors::queues

define gridengine::collectors::queues($store, $config)
{

    gridengine::collector { $title:
        dir       => 'queues',
        sourcedir => $store,
        config    => $config,
    }

}
