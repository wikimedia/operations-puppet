class profile::bastionhost::twofa {

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
        content => template('profile/bastionhost/pam-sshd.erb'),
        require => Package['openssh-server'],
    }
}
