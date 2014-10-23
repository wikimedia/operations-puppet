# gridengine/exec_host.pp

class gridengine::exec_host(
    $config = undef,
)
{
    $etcdir = '/var/lib/gridengine/etc'

    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    gridengine::resource { "${::fqdn}":
        dir     => 'exechosts',
        content => $config,
    }

}

