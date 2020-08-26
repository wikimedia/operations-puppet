# @summary configure cfssl api service
class cfssl (
    Stdlib::Port     $port             = 8888,
    Stdlib::Host     $host            = 'localhost',
    Cfssl::Loglevel  $log_level       = 'info',
    Stdlib::Unixpath $conf_dir        = '/etc/cfssl',
    Optional[String] $ca_key_content  = undef,
    Optional[String] $ca_cert_content = undef,
) {
    ensure_packages(['golang-cfssl'])
    $conf_file = "${conf_dir}/cfssl.conf"
    $csr_dir = "${conf_dir}/csr"
    $internal_dir = "${conf_dir}/internal"
    $ca_key_file = '/etc/ssl/private/ca_key.pem'
    $ca_file = '/etc/ssl/certs/ca.pem'

    file{[$conf_dir, $csr_dir, $internal_dir]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        require => Package['golang-cfssl'],
    }
    if $ca_key_content and $ca_cert_content {
        file {
            default:
                ensure => file,
                owner  => 'root',
                group  => 'root',
                mode   => '0400';
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
