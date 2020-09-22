# @summary a resource for creating csr json files
define cfssl::csr (
    Cfssl::Key                    $key,
    Array[Cfssl::Name]            $names,
    Cfssl::Signer_config          $signer_config,
    Wmflib::Ensure                $ensure        = 'present',
    String                        $profile       = 'default',
    String                        $owner         = 'root',
    String                        $group         = 'root',
    Boolean                       $auto_renew    = true,
    Integer[1800]                 $renew_seconds = 604800,  # 1 week
    Optional[Array[Stdlib::Host]] $hosts         = [],
    Optional[Stdlib::Unixpath]    $outdir        = undef,

) {
    include cfssl

    if $key['algo'] == 'rsa' and $key['size'] < 2048 {
        fail('RSA keys must be either 2048, 4096 or 8192 bits')
    }
    if $key['algo'] == 'ecdsa' and $key['size'] > 2048 {
        fail('ECDSA keys must be either 256, 384 or 521 bits')
    }
    $ensure_file = $ensure ? {
        'present' => 'file',
        default   => $ensure,
    }

    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')
    $csr_json_path = "${cfssl::csr_dir}/${safe_title}.csr"
    $_outdir   = $outdir ? {
        undef   => "${cfssl::ssl_dir}/${safe_title}",
        default => $outdir,
    }

    $_names = $names.map |Cfssl::Name $name| {
        {
            'C'  => $name['country'],
            'L'  => $name['locality'],
            'O'  => $name['organisation'],
            'OU' => $name['organisational_unit'],
            'S'  => $name['state'],
        }
    }
    $csr = {
        'CN'    => $title,
        'hosts' => $hosts,
        'key'   => $key,
        'names' => $_names,
    }
    file{$csr_json_path:
        ensure  => $ensure_file,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => $csr.to_json_pretty()
    }
    file {$_outdir:
        ensure  => ensure_directory($ensure),
        owner   => $owner,
        group   => $group,
        mode    => '0440',
        recurse => true,
        purge   => true,
    }
    $signer_args = $signer_config ? {
        Stdlib::HTTPUrl              => "-remote ${signer_config}",
        Cfssl::Signer_config::Client => "-config ${signer_config['config_file']}",
        default                      => @("SIGNER_ARGS"/L)
            -ca=${signer_config['config_dir']}/ca/ca.pem \
            -ca-key=${signer_config['config_dir']}/ca/ca_key.pem \
            -config=${signer_config['config_dir']}/cfssl.conf \
            | SIGNER_ARGS
    }
    $cert_path = "${_outdir}/${safe_title}.pem"
    $key_path = "${_outdir}/${safe_title}-key.pem"
    $csr_pem_path = "${_outdir}/${safe_title}.csr"
    $gen_command = @("GEN_COMMAND"/L)
        /usr/bin/cfssl gencert ${signer_args} -profile=${profile} ${csr_json_path} \
        | /usr/bin/cfssljson -bare ${_outdir}/${safe_title}
        | GEN_COMMAND

    # TODO: would be nice to check its signed with the correct CA
    $test_command = @("TEST_COMMAND"/L)
        /usr/bin/test \
        "$(/usr/bin/openssl x509 -in ${cert_path} -noout -pubkey)" == \
        "$(/usr/bin/openssl pkey -pubout -in ${key_path})"
        | TEST_COMMAND
    if $ensure == 'present' {
        exec{"Generate cert ${title}":
            command => $gen_command,
            unless  => $test_command,
        }
    }
    if $auto_renew {
        exec {'renew certificate':
            command => $gen_command.regsubst('gencert', 'sign'),
            unless  => "/usr/bin/openssl x509 -in ${cert_path} -checkend ${renew_seconds}",
        }
    }

    file{[$cert_path, $key_path, $csr_pem_path]:
        ensure => $ensure_file,
        owner  => $owner,
        group  => $group,
        mode   => '0440',
    }
}
