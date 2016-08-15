class ssh::client {
    package { 'openssh-client':
        ensure => present,
    }

    # no exported resources on Labs == no sshknowngen
    if $::realm == 'production' {
        if $::use_puppetdb {
            file { '/etc/ssh/ssh_known_hosts':
                content => template('ssh/known_hosts.erb'),
                backup  => false,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
            }
        } else {
            file { '/etc/ssh/ssh_known_hosts':
                content => generate('/usr/local/bin/sshknowngen'),
                backup  => false,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
            }
        }
    }
}
