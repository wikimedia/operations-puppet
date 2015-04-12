# gridengine/exec_host.pp

class gridengine::exec_host(
    $config = undef,
)
{
    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    gridengine::resource { "exec-${::fqdn}":
        rname   => $::fqdn,
        dir     => 'exechosts',
        config  => $config,
    }

    file { '/usr/local/bin/gridengine-mailer':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/gridengine-mailer',
    }
}
