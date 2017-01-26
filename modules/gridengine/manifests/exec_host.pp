# gridengine/exec_host.pp

class gridengine::exec_host(
    $config = undef,
) {

    include ::gridengine

    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    service { 'gridengine-exec':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        pattern   => 'sge_execd',
        require   => Package['gridengine-exec'],
    }

    gridengine::resource { "exec-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'exechosts',
        config => $config,
    }
}
