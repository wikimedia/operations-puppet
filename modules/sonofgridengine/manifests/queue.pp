# sonofgridengine/queue.pp

define sonofgridengine::queue(
    $rname   = $title,
    $config  = undef,
) {

    gridengine::resource { $rname:
        dir    => 'queues',
        config => $config,
    }
}
