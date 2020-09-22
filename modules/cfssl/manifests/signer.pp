# @summary configure cfssl api service
# @param ca_key_content content of the CA private key
# @param ca_cert_content content of the CA public key
# @param host hostname of the cfssl server
# @param port port of the cfssl server
# @param ocsp_port ocsp_port of the cfssl server
# @param log_level the logging level
# @param default_auth_key the default authentication key
# @param default_expiry the default signing expiry time
# @param default_usages the default signing usages
# @param default_crl_url the URL of the CRL
# @param default_ocsp_url the URL of the OCSP responder
# @param ocsp_cert_path path to the ocsp certificate
# @param ocsp_key_path path to the ocsp private key
# @param profiles A hash of signing profiles
# @param auth_keys A hash of authentication keys, this must contain an entry for the default_auth_key
define cfssl::signer (
    String                        $ca_key_content,
    String                        $ca_cert_content,
    Stdlib::Host                  $host             = $facts['fqdn'],
    Stdlib::Port                  $port             = 8888,
    Stdlib::Port                  $ocsp_port        = 8889,
    Cfssl::Loglevel               $log_level        = 'info',
    String                        $default_auth_key = 'default_auth',
    Cfssl::Expiry                 $default_expiry   = '720h',
    Array[Cfssl::Usage]           $default_usages   = ['signing', 'key encipherment', 'client auth'],
    Stdlib::HTTPUrl               $default_crl_url  = "http://${host}:${port}/crl",
    Stdlib::HTTPUrl               $default_ocsp_url = "http://${host}:${ocsp_port}",
    Wmflib::Ensure                $serve_ensure     = 'absent',
    Hash[String, Cfssl::Profile]  $profiles         = {},
    Hash[String, Cfssl::Auth_key] $auth_keys        = {},
    Optional[Stdlib::Unixpath]    $ocsp_cert_path   = undef,
    Optional[Stdlib::Unixpath]    $ocsp_key_path    = undef,
) {
    include cfssl
    $safe_title = $title.regsubst('\W', '_', 'G')
    $conf_dir = "${cfssl::signer_dir}/${safe_title}"
    $conf_file = "${cfssl::signer_dir}/${safe_title}/cfssl.conf"
    $db_conf_file = "${conf_dir}/db.conf"
    $db_path = "${conf_dir}/cfssl.db"
    $ca_dir = "${conf_dir}/ca"
    $ca_key_file = "${ca_dir}/ca_key.pem"
    $ca_file = "${ca_dir}/ca.pem"
    $ocsp_response_path = "${ca_dir}/ocspdump.txt"
    cfssl::config{$safe_title:
        default_auth_key => $default_auth_key,
        default_expiry   => $default_expiry,
        default_usages   => $default_usages,
        default_crl_url  => $default_crl_url,
        default_ocsp_url => $default_ocsp_url,
        auth_keys        => $auth_keys,
        profiles         => $profiles,
        path             => $conf_file,
    }
    $db_config = {'driver' => 'sqlite3', 'data_source' => $db_path}

    file{
        default:
            owner   => 'root',
            group   => 'root',
            require => Package[$cfssl::packages];
        [$conf_dir, $ca_dir]:
            ensure => directory,
            mode   => '0550';
        $db_conf_file:
            ensure  => file,
            mode    => '0440',
            content => $db_config.to_json(),
            notify  => Service['cfssl'];
    }
    sqlite::db {'cfssl':
        db_path    => $db_path,
        sql_schema => "${cfssl::sql_dir}/sqlite_initdb.sql",
        require    => File["${cfssl::sql_dir}/sqlite_initdb.sql"],
    }
    if $ca_key_content and $ca_cert_content {
        file {
            default:
                ensure => file,
                owner  => 'root',
                group  => 'root',
                mode   => '0400',
                notify => Service['cfssl'];
            $ca_key_file:
                content => $ca_key_content;
            $ca_file:
                content => $ca_cert_content,
                mode    => '0444';
        }
    }
    systemd::service {'cfssl':
        ensure  => $serve_ensure,
        content => template('cfssl/cfssl.service.erb'),
        restart => true,
    }
    $ocsp_ensure = ($ocsp_cert_path and $ocsp_key_path) ? {
        true    => 'present',
        default => 'absent',
    }
    systemd::service {'cfssl-ocsp':
        ensure  => $ocsp_ensure,
        content => template('cfssl/cfssl-ocsp.service.erb'),
        restart => true,
    }
}
