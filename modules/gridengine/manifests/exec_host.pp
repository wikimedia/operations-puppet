# gridengine/exec_host.pp

class gridengine::exec_host( $collectdir = undef )
{
    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }
}

