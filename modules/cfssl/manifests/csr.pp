# @summary a resource for creating csr json files
define cfssl::csr (
    Cfssl::Key                    $key,
    Array[Cfssl::Name]            $names,
    Cfssl::Signer_config          $signer_config,
    String                        $profile       = 'default',
    String                        $owner         = 'root',
    String                        $group         = 'root',
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

    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')
    $csr_file = "${cfssl::csr_dir}/${safe_title}.csr"
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
    file{$csr_file:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => $csr.to_json_pretty()
    }
    file {$_outdir:
        ensure  => directory,
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
    $gen_command = @("GEN_COMMAND"/L)
        /usr/bin/cfssl gencert ${signer_args} -profile=${profile} ${csr_file} \
        | /usr/bin/cfssljson -bare ${_outdir}/${safe_title}
        | GEN_COMMAND
    exec{"Generate cert ${title}":
        command => $gen_command,
        creates => "${_outdir}/${safe_title}-key.pem"
    }
}
