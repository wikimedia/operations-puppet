# SPDX-License-Identifier: Apache-2.0
# @summary a resource for creating csr json files
define cfssl::cert (
    String                         $common_name    = $title,
    Array[Cfssl::Name]             $names          = [],
    Cfssl::Key                     $key            = {'algo' => 'ecdsa', 'size' => 256},
    Wmflib::Ensure                 $ensure         = 'present',
    String                         $owner          = 'root',
    String                         $group          = 'root',
    Boolean                        $auto_renew     = true,
    # the default https checks go warning after 10 full days i.e. anywhere
    # from 864000 to 950399 seconds before the certificate expires.  As such set this to
    # 11 days + 30 minutes to capture the puppet run schedule.
    Integer[1800]                  $renew_seconds  = 952200,
    Boolean                        $provide_chain  = false,
    # We need this because the puppet CA cert used for TLS mutual auth has no SAN
    Array[String]                  $environment    = ['GODEBUG=x509ignoreCN=0'],
    Optional[String]               $label          = undef,
    Optional[String]               $profile        = undef,
    Optional[String]               $notify_service = undef,
    Optional[Stdlib::Unixpath]     $outdir         = undef,
    Optional[Stdlib::Unixpath]     $tls_cert       = undef,
    Optional[Stdlib::Unixpath]     $tls_key        = undef,
    Optional[Stdlib::Unixpath]     $tls_remote_ca  = undef,
    Optional[Cfssl::Signer_config] $signer_config  = undef,
    Array[Cfssl::Common_name]      $hosts          = [],

) {
    include cfssl
    include cfssl::client
    $_tls_cert = $tls_cert ? {
        undef   => $cfssl::client::mutual_tls_client_cert,
        default => $tls_cert,
    }
    $_tls_key = $tls_key ? {
        undef   => $cfssl::client::mutual_tls_client_key,
        default => $tls_key,
    }
    $_tls_remote_ca = $tls_remote_ca ? {
        undef   => $cfssl::client::tls_remote_ca,
        default => $tls_remote_ca,
    }
    # use the client config by default
    $_signer_config = pick($signer_config, {'config_file' => $cfssl::client::conf_file})

    if $key['algo'] == 'rsa' and $key['size'] < 2048 {
        fail('RSA keys must be either 2048, 4096 or 8192 bits')
    }
    if $key['algo'] == 'ecdsa' and $key['size'] > 2048 {
        fail('ECDSA keys must be either 256, 384 or 521 bits')
    }

    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')
    $csr_json_path = "${cfssl::csr_dir}/${safe_title}.csr"
    $_outdir   = $outdir ? {
        undef   => "${cfssl::ssl_dir}/${safe_title}",
        default => $outdir,
    }

    cfssl::csr { $csr_json_path:
        common_name => $common_name,
        key         => $key,
        names       => $names,
        hosts       => $hosts,
    }

    unless defined(File[$_outdir]) {
        file {$_outdir:
            ensure  => stdlib::ensure($ensure, 'directory'),
            owner   => $owner,
            group   => $group,
            recurse => true,
            mode    => '0740',
        }
    }
    $tls_config = ($_tls_cert and $_tls_key) ? {
        true    => "-mutual-tls-client-cert ${_tls_cert} -mutual-tls-client-key ${_tls_key}",
        default => '',
    }
    $tls_remote_ca_config = $_tls_remote_ca ? {
        undef   => '',
        default => "-tls-remote-ca ${_tls_remote_ca}",
    }
    $_label = $label ? {
        undef   => '',
        default => "-label ${label}",
    }
    $_profile = $profile ? {
        undef   => '',
        default => "-profile ${profile}",
    }
    $signer_args = $_signer_config ? {
        Stdlib::HTTPUrl              => "-remote ${_signer_config} ${tls_remote_ca_config} ${tls_config} ${_label}",
        Cfssl::Signer_config::Client => "-config ${_signer_config['config_file']} ${tls_remote_ca_config} ${tls_config} ${_label}",
        default                      => @("SIGNER_ARGS"/L)
            -ca=${_signer_config['config_dir']}/ca/ca.pem \
            -ca-key=${_signer_config['config_dir']}/ca/ca-key.pem \
            -config=${_signer_config['config_dir']}/cfssl.conf \
            -db-config=${_signer_config['config_dir']}/db.conf \
            | SIGNER_ARGS
    }
    $cert_path = "${_outdir}/${safe_title}.pem"
    $key_path = "${_outdir}/${safe_title}-key.pem"
    $csr_pem_path = "${_outdir}/${safe_title}.csr"
    $gen_command = @("GEN_COMMAND"/L)
        /usr/bin/cfssl gencert ${signer_args} ${_profile} ${csr_json_path} \
        | /usr/bin/cfssljson -bare ${_outdir}/${safe_title}
        | GEN_COMMAND
    $sign_command = @("SIGN_COMMAND"/L)
        /usr/bin/cfssl sign ${signer_args} ${_profile} ${csr_pem_path} \
        | /usr/bin/cfssljson -bare ${_outdir}/${safe_title}
        | SIGN_COMMAND

    # TODO: would be nice to check its signed with the correct CA
    $test_command = @("TEST_COMMAND"/L)
        /usr/bin/test \
        "$(/usr/bin/openssl x509 -in ${cert_path} -noout -pubkey 2>&1)" == \
        "$(/usr/bin/openssl pkey -pubout -in ${key_path} 2>&1)"
        | TEST_COMMAND
    if $ensure == 'present' {
        $_notify_service = $notify_service ? {
            undef   => undef,
            default => Service[$notify_service],
        }
        exec{"Generate cert ${title}":
            command     => $gen_command,
            environment => $environment,
            unless      => $test_command,
            notify      => $_notify_service,
            require     => Cfssl::Csr[$csr_json_path],
        }
        exec{"Generate cert ${title} refresh":
            command     => $gen_command,
            environment => $environment,
            refreshonly => true,
            notify      => $_notify_service,
            subscribe   => File[$csr_json_path],
        }
        if $auto_renew {
            exec {"renew certificate - ${title}":
                command     => $sign_command,
                environment => $environment,
                unless      => "/usr/bin/openssl x509 -in ${cert_path} -checkend ${renew_seconds}",
                require     => Exec["Generate cert ${title}"],
                notify      => $_notify_service,
            }
        }
    }

    file { [$cert_path, $csr_pem_path]:
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => $owner,
        group  => $group,
        mode   => '0440',
    }
    file { $key_path:
        ensure    => stdlib::ensure($ensure, 'file'),
        owner     => $owner,
        group     => $group,
        mode      => '0440',
        show_diff => false,
        backup    => false,
    }
    if $provide_chain {
        # TODO: we need to replace how we fetch bundles as fetching over a
        # http source seems like a really bad idea.
        # Ideally the gencert command would support the bundle options but
        # there has been little progress on this upstream
        # https://github.com/cloudflare/cfssl/issues/779
        # We may be better of implementing the certificate creations directly
        # via the API
        unless $label {
            fail('you must provide a $label if specifying $provide_chain')
        }
        # Just copy the CA file locally once
        $cert_chain_path = "${_outdir}/${safe_title}.chain.pem"
        $cert_chained_path = "${_outdir}/${safe_title}.chained.pem"
        file { $cert_chain_path:
            ensure => stdlib::ensure($ensure, 'file'),
            owner  => $owner,
            group  => $group,
            mode   => '0440',
            source => "${cfssl::client::bundles_source}/${label}.pem",
        }

        $test_chained = @("TEST_CHAINED"/L)
            /usr/bin/test \
            "$(/bin/cat ${cert_path} ${cert_chain_path} | sha512sum)" == \
            "$(/bin/cat ${cert_chained_path} | sha512sum)"
            | TEST_CHAINED
        # TODO: use sslcert::chained
        $subscribe = $auto_renew ? {
            true    => [Exec["renew certificate - ${title}"], File[$cert_chain_path, $cert_path]],
            default => File[$cert_chain_path, $cert_path],
        }
        exec {"create chained cert ${cert_chain_path}":
            command   => "/bin/cat ${cert_path} ${cert_chain_path} > ${cert_chained_path}",
            unless    => $test_chained,
            notify    => $_notify_service,
            subscribe => $subscribe,
        }
        file { $cert_chained_path:
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => $owner,
            group   => $group,
            require => Exec["create chained cert ${cert_chain_path}"],
        }
    }
}
