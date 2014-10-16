# gridengine/queue.pp

define gridengine::queue(
    $etcdir  = '/etc/gridengine/local',
    $name    = $title,
    $source  = undef,
    $content = undef )
{

    gridengine::resource($name:
        etcdir => $etcdir,
        dir    => 'queues',
        source => $source,
        addcmd => '/usr/bin/qconf -Aq',
        modcmd => '/usr/bin/qconf -Mq',
        delcmd => '/usr/bin/qconf -dq',
    )

}

