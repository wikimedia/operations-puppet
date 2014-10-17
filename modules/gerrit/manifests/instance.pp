# Manifest to setup a Gerrit instance

class gerrit::instance($apache_ssl  = false,
    $slave       = false,
    $ssh_port    = '29418',
    $db_host     = '',
    $db_name     = 'reviewdb',
    $host        = '',
    $db_user     = 'gerrit',
    $ssh_key     = '',
    $ssl_cert    = 'ssl-cert-snakeoil',
    $ssl_cert_key= 'ssl-cert-snakeoil',
    $replication = '',
    $smtp_host   = '') {

    include standard,
        ldap::role::config::labs

    # Main config
    include passwords::gerrit
    $email_key = $passwords::gerrit::gerrit_email_key
    $sshport = $ssh_port
    $dbhost = $db_host
    $dbname = $db_name
    $dbuser = $db_user
    $dbpass = $passwords::gerrit::gerrit_db_pass
    $bzpass = $passwords::gerrit::gerrit_bz_pass

    # Setup LDAP
    include ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    $ldap_hosts = $ldapconfig['servernames']
    $ldap_base_dn = $ldapconfig['basedn']
    $ldap_proxyagent = $ldapconfig['proxyagent']
    $ldap_proxyagent_pass = $ldapconfig['proxypass']

    # Configure the base URL
    $url = "https://${host}/r"

    class { 'gerrit::proxy':
        ssl_cert     => $ssl_cert,
        ssl_cert_key => $ssl_cert_key,
        host         => $host
    }

    class { 'gerrit::jetty':
        ldap_hosts           => $ldap_hosts,
        ldap_base_dn         => $ldap_base_dn,
        url                  => $url,
        dbhost               => $dbhost,
        dbname               => $dbname,
        dbuser               => $dbuser,
        hostname             => $host,
        ldap_proxyagent      => $ldap_proxyagent,
        ldap_proxyagent_pass => $ldap_proxyagent_pass,
        sshport              => $sshport,
        replication          => $replication,
        smtp_host            => $smtp_host,
        ssh_key              => $ssh_key,
    }
}
