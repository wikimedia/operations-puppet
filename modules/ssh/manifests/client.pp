class ssh::client {
    package { 'openssh-client':
        ensure => present,
    }

    if $::use_puppetdb {
        file { '/etc/ssh/ssh_known_hosts':
            content => template('ssh/known_hosts.erb'),
            backup  => false,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
        }
    } elsif $::realm == 'production' {
        # Effectively unused at the moment as production has use_puppetdb
        file { '/etc/ssh/ssh_known_hosts':
            content => generate('/usr/local/bin/sshknowngen'),
            backup  => false,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
        }
    }
}
