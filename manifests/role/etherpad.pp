class role::etherpad{
    include ::etherpad
    system::role { 'etherpad': description => 'Etherpad-lite server' }

    $etherpad_db_user = $passwords::etherpad_lite::etherpad_db_user
    $etherpad_db_host = $passwords::etherpad_lite::etherpad_db_host
    $etherpad_db_name = $passwords::etherpad_lite::etherpad_db_name
    $etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass

    if $::realm == 'labs' {
        $etherpad_host = $::fqdn
        $etherpad_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
        $etherpad_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key'
    } else {
        $etherpad_host = 'etherpad.wikimedia.org'
        $etherpad_serveraliases = 'epl.wikimedia.org'
        install_certificate{ 'etherpad.wikimedia.org': }
        $etherpad_ssl_cert = '/etc/ssl/certs/etherpad.wikimedia.org.pem'
        $etherpad_ssl_key = '/etc/ssl/private/etherpad.wikimedia.org.key'
    }
}
