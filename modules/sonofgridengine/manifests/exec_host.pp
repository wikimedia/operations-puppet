# sonofgridengine/exec_host.pp

class sonofgridengine::exec_host(
    $config = undef,
) {

    include ::sonofgridengine

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

    sonofgridengine::resource { "exec-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'exechosts',
        config => $config,
    }
}
