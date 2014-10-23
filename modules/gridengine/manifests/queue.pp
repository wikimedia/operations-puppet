# gridengine/queue.pp

define gridengine::queue(
    $qname   = $title,
    $source  = undef,
    $content = undef )
{

    gridengine::resource { $qname:
        dir     => 'queues',
        source  => $source,
        content => $content,
    }

}

