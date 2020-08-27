# @summary a resource for creating csr json files
define cfssl::csr (
    Cfssl::Key                    $key,
    Array[Cfssl::Name]            $names,
    String                        $profile = 'default',
    Optional[Array[Stdlib::Host]] $hosts = [],
) {
    include cfssl

    if $key['algo'] == 'rsa' and $key['size'] < 2048 {
        fail('RSA keys must be either 2048, 4096 or 8192 bits')
    }
    if $key['algo'] == 'ecdsa' and $key['size'] > 2048 {
        fail('ECDSA keys must be either 256, 384 or 521 bits')
    }
    unless $profile in $cfssl::profiles.keys() {
        fail("${profile} is not a valid profile")
    }

    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')
    $csr_file = "${cfssl::csr_dir}/${safe_title}.csr"
    $outdir   = "${cfssl::internal_dir}/${profile}"

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
    $gen_command = @("GENCOMMAND"/L)
        /usr/bin/cfssl gencert -ca=${cfssl::ca_file} -ca-key=${cfssl::ca_key_file} -config=${cfssl::conf_file}
         -profile=${profile} ${csr_file} | /usr/bin/cfssljson -bare ${outdir}/${title}
        | GENCOMMAND
    exec{"Generate cert ${title}":
        command => $gen_command,
        creates => "${outdir}/${title}.key"
    }
}
