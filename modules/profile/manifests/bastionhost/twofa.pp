class profile::bastionhost::twofa {
    system::role { 'bastionhost::twofa':
        description => 'Bastion host using two factor authentication',
    }

    class{'::profile::bastionhost::base'}

    include ::passwords::yubiauth

    require_package('libpam-yubico')

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
