class role::yubiauth_server {

    system::role { 'yubiauth_server':
        ensure      => 'present',
        description => 'Yubi 2FA authentication server',
    }

    include ::profile::standard
    include ::profile::backup::host
    include ::profile::yubiauth::server
}
