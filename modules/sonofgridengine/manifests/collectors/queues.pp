# gridengine::collectors::queues

define sonofgridengine::collectors::queues($store, $config)
{

    gridengine::collector { $title:
        dir       => 'queues',
        sourcedir => $store,
        config    => $config,
    }

}
