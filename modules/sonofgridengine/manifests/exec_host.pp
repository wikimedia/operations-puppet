# SPDX-License-Identifier: Apache-2.0
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

    sonofgridengine::resource { "exec-${facts['hostname']}.${::wmcs_project}.eqiad1.wikimedia.cloud":
        rname  => "${facts['hostname']}.${::wmcs_project}.eqiad1.wikimedia.cloud",
        dir    => 'exechosts',
        config => $config,
    }
}
