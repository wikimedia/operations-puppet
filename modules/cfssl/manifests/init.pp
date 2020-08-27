# @summary configure cfssl api service
class cfssl (
    Stdlib::Host                 $host            = $facts['fqdn'],
    Stdlib::Port                 $port            = 8888,
    Cfssl::Loglevel              $log_level       = 'info',
    Stdlib::Unixpath             $conf_dir        = '/etc/cfssl',
    Cfssl::Expiry                $default_expiry  = '720h',
    Array[Cfssl::Usage]          $default_usages  = ['signing', 'key encipherment', 'client auth'],
    Stdlib::HTTPUrl              $crl_url         = "http://${host}:${port}/crl",
    Hash[String, Cfssl::Profile] $profiles        = {},
    Optional[String]             $ca_key_content  = undef,
    Optional[String]             $ca_cert_content = undef,
) {
    ensure_packages(['golang-cfssl'])
    $conf_file = "${conf_dir}/cfssl.conf"
    $csr_dir = "${conf_dir}/csr"
    $ca_dir = "${conf_dir}/ca"
    $internal_dir = "${conf_dir}/internal"
    $ca_key_file = "${ca_dir}/ca_key.pem"
    $ca_file = "${ca_dir}/ca.pem"
    $config = {
        'signing' => {
            'default'  => {
                'crl_url' => $crl_url,
                'expiry'  => $default_expiry,
                'usages'  => $default_usages,
            },
            'profiles' => $profiles,
        }
    }
    $profile_dirs = $profiles.keys().map |$profile| { "${internal_dir}/${profile}" }

    file{
        default:
            owner   => 'root',
            group   => 'root',
            require => Package['golang-cfssl'];
        [$conf_dir, $csr_dir, $internal_dir, $ca_dir] + $profile_dirs:
            ensure => directory,
            mode   => '0550';
        $conf_file:
            ensure  => file,
            mode    => '0440',
            content => $config.to_json(),
            notify  => Service['cfssl'];
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
