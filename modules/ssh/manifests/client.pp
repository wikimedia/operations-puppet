class ssh::client {
    package { 'openssh-client':
        ensure => present,
    }

    # no exported resources on Labs == no sshknowngen
    if $::realm == 'production' {
        # Note: For some reason (ruby symbol?), $settings::storeconfigs_backend
        # would never match in the if clause below. So define a new variable and
        # cast the variable to string
        $settings_storeconfigs_backend = "${settings::storeconfigs_backend}"
        if $settings_storeconfigs_backend == 'puppetdb' {
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
