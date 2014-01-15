class role::etherpad{

    system::role { 'etherpad': description => 'Etherpad-lite server' }

    class ::etherpad(
    $etherpad_db_user = $passwords::etherpad_lite::etherpad_db_user,
    $etherpad_db_host = $passwords::etherpad_lite::etherpad_db_host,
    $etherpad_db_name = $passwords::etherpad_lite::etherpad_db_name,
    $etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass,
){
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
    # Icinga process monitoring, RT #5790
    nrpe::monitor_service { 'etherpad-lite-proc':
        description   => 'etherpad_lite_process_running',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array='^node node_modules/ep_etherpad-lite/node/server.js'",
    }
}
