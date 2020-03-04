# @summary initiate the certificate authority
class cfssl::initca (
    String $ca_name,
    Hash $ca_config,
) {
    include cfssl

    $safe_title = $ca_name.regsubst('[^\w\-]', '_', 'G')
    $csr_path = "${cfssl::csr_dir}/${safe_title}.csr"
    $ca_file = $cfssl::ca_file
    $ca_key_file = $cfssl::ca_key_file

    cfssl::csr {$ca_name:
        sign => false,
        *    => $ca_config,
    }
    file {'/usr/local/sbin/cfssl_initca':
        ensure  => file,
        owner   => 'root',
        mode    => '0500',
        content => template('cfssl/initca.sh.erb'),
    }
    exec {'/usr/local/sbin/cfssl_initca':
        creates => $ca_key_file,
        require => File['/usr/local/sbin/cfssl_initca'],
    }
}
