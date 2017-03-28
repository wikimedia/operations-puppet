class role::yubiauth_server {

    include ::standard
    include ::role::backup::host
    include ::profile::yubiauth::server
}
