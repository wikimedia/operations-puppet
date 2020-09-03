# @summary configure cfssl api service
# @param ca_key_content content of the CA private key
# @param ca_cert_content content of the CA public key
# @param host hostname of the cfssl server
# @param port port of the cfssl server
# @param ocsp_port ocsp_port of the cfssl server
# @param log_level the logging level
# @param conf_dir location of the configuration directory
# @param default_auth_key the default authentication key
# @param default_expiry the default signing expiry time
# @param default_usages the default signing usages
# @param crl_url the URL of the CRL
# @param ocsp_url the URL of the OCSP responder
# @param ocsp_cert_path path to the ocsp certificate
# @param ocsp_key_path path to the ocsp private key
# @param profiles A hash of signing profiles
# @param auth_keys A hash of authentication keys, this must contain an entry for the default_auth_key
class cfssl (
    String                        $ca_key_content,
    String                        $ca_cert_content,
    Stdlib::Host                  $host             = $facts['fqdn'],
    Stdlib::Port                  $port             = 8888,
    Stdlib::Port                  $ocsp_port        = 8889,
    Cfssl::Loglevel               $log_level        = 'info',
    Stdlib::Unixpath              $conf_dir         = '/etc/cfssl',
    String                        $default_auth_key = 'default_auth',
    Cfssl::Expiry                 $default_expiry   = '720h',
    Array[Cfssl::Usage]           $default_usages   = ['signing', 'key encipherment', 'client auth'],
    Stdlib::HTTPUrl               $crl_url          = "http://${host}:${port}/crl",
    Stdlib::HTTPUrl               $ocsp_url         = "http://${host}:${ocsp_port}",
    Optional[Stdlib::Unixpath]    $ocsp_cert_path  = undef,
    Optional[Stdlib::Unixpath]    $ocsp_key_path   = undef,
    Hash[String, Cfssl::Profile]  $profiles         = {},
    Hash[String, Cfssl::Auth_key] $auth_keys        = {},
) {
    unless $auth_keys.has_key($default_auth_key) {
        fail("auth_keys must have an entry for '${default_auth_key}'")
    }
    ensure_packages(['golang-cfssl'])
    $conf_file = "${conf_dir}/cfssl.conf"
    $db_conf_file = "${conf_dir}/db.conf"
    $db_path = "${conf_dir}/cfssl.db"
    $csr_dir = "${conf_dir}/csr"
    $ca_dir = "${conf_dir}/ca"
    $internal_dir = "${conf_dir}/internal"
    $ca_key_file = "${ca_dir}/ca_key.pem"
    $ca_file = "${ca_dir}/ca.pem"
    $sql_dir = '/usr/local/share/cfssl'
    # make sure all profiles use the default auth key
    # first map to an array of [key, values] then convert to a hash
    $_profiles = Hash($profiles.map |$key, $value| {
        [$key, {'auth_key' => $default_auth_key} + $value]
    })
    $config = {
        'auth_keys' => $auth_keys,
        'signing' => {
            'default'   => {
                'auth_key' => $default_auth_key,
                'crl_url'  => $crl_url,
                'ocsp_url' => $ocsp_url,
                'expiry'   => $default_expiry,
                'usages'   => $default_usages,
            },
            'profiles'  => $_profiles,
        }
    }
    $db_config = {'driver' => 'sqlite3', 'data_source' => $db_path}
    $profile_dirs = $profiles.keys().map |$profile| { "${internal_dir}/${profile}" }
    $enable_ocsp = ($ocsp_cert_path and $ocsp_key_path)

    file{
        default:
            ensure  => file,
            mode    => '0440',
            owner   => 'root',
            group   => 'root',
            require => Package['golang-cfssl'];
        [$conf_dir, $csr_dir, $internal_dir, $ca_dir, $sql_dir] + $profile_dirs:
            ensure => directory,
            mode   => '0550';
        $conf_file:
            content => $config.to_json(),
            notify  => Service['cfssl'];
        $db_conf_file:
            content => $db_config.to_json(),
            notify  => Service['cfssl'];
        "${sql_dir}/sqlite_initdb.sql":
            source => 'puppet:///modules/cfssl/sqlite_initdb.sql';
    }
    sqlite::db {'cfssl':
        db_path    => $db_path,
        sql_schema => "${sql_dir}/sqlite_initdb.sql",
        require    => File["${sql_dir}/sqlite_initdb.sql"],
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
        content => template('cfssl/cfssl.service.erb'),
        restart => true,
    }
}
