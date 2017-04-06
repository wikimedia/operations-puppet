class role::bastionhost::twofa {
    system::role { 'bastionhost::twofa':
        description => 'Bastion host using two factor authentication',
    }

    include ::bastionhost
    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    include ::passwords::yubiauth

    backup::set {'home': }

    require_package('libpam-yubico')

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

    $api_key = $passwords::yubiauth::api_key

    file { '/etc/pam.d/sshd':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('role/bastionhost/pam-sshd.erb'),
        require => Package['openssh-server'],
    }
}
