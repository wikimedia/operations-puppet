# gridengine/queue.pp

define gridengine::queue(
    $rname   = $title,
    $config  = undef )
{

    gridengine::resource { $rname:
        dir     => 'queues',
        source  => $source,
        config  => $config,
    }

}

