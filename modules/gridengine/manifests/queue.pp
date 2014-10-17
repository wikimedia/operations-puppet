# gridengine/queue.pp

define gridengine::queue(
    $etcdir  = '/etc/gridengine/local',
    $qname   = $title,
    $source  = undef,
    $content = undef )
{

    gridengine::resource { $qname:
        etcdir => $etcdir,
        dir    => 'queues',
        source => $source,
        addcmd => '/usr/bin/qconf -Aq',
        modcmd => '/usr/bin/qconf -Mq',
        delcmd => '/usr/bin/qconf -dq',
    }

}

