# sonofgridengine/queue.pp

define sonofgridengine::queue(
    $rname   = $title,
    $config  = undef,
) {

    soneofgridengine::resource { $rname:
        dir    => 'queues',
        config => $config,
    }
}
