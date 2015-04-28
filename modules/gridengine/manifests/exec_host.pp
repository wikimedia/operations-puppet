# gridengine/exec_host.pp

class gridengine::exec_host(
    $config = undef,
)
{
    include gridengine

    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    gridengine::resource { "exec-${::fqdn}":
        rname   => $::fqdn,
        dir     => 'exechosts',
        config  => $config,
    }

}

