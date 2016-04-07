class role::bastionhost::2fa {
    system::role { 'bastionhost::2fa':
        description => 'Bastion host using two factor authentication',
    }

    include ::bastionhost
    include standard
    include base::firewall
    include role::backup::host

    backup::set {'home': }

    require_package('libpam-yubico')

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

    file { '/etc/pam.d/sshd':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('role/bastionhost/pam-sshd.erb'),
        require => Package['openssh-server'],
    }
}
