class role::yubiauth_server {

    include ::standard
    include ::profile::backup::host
    include ::profile::yubiauth::server
}
