# gridengine::collectors::queues

define sonofgridengine::collectors::queues($store, $config)
{

    sonofgridengine::collector { $title:
        dir       => 'queues',
        sourcedir => $store,
        config    => $config,
    }

}
