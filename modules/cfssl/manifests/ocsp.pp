# SPDX-License-Identifier: Apache-2.0
# Title should match the cfssl::signer title
# @param ocsprefresh_update if true update the ocsp response table otherwise just check for updates
define cfssl::ocsp (
    Stdlib::Fqdn                $common_name        = $facts['fqdn'],
    Stdlib::IP::Address         $listen_addr        = '127.0.0.1',
    Stdlib::Port                $listen_port        = 8889,
    Cfssl::Loglevel             $log_level          = 'info',
    Pattern[/\d+h/]             $refresh_interval   = '96h',
    Boolean                     $ocsprefresh_update = false,
    Array[Cfssl::Common_name]   $additional_names   = [],
    Optional[Stdlib::Unixpath]  $responses_file     = undef,
    Optional[Stdlib::Unixpath]  $db_conf_file       = undef,
    Optional[Sensitive[String]] $key_content        = undef,
    Optional[String]            $cert_content       = undef,
    Optional[Stdlib::Unixpath]  $ca_file            = undef,
) {
    include cfssl
    include cfssl::client

    $safe_title         = $title.regsubst('\W', '_', 'G')
    $outdir             = "${cfssl::ssl_dir}/ocsp"
    $refresh_timer      = "cfssl-ocsprefresh-${safe_title}"
    $serve_service      = "cfssl-ocspserve@${safe_title}"
    $safe_cert_name     = "OCSP ${title} ${common_name}".regsubst('[^\w\-]', '_', 'G')
    $key_path           = "${outdir}/${safe_cert_name}-key.pem"
    $cert_path          = "${outdir}/${safe_cert_name}.pem"

    $_db_conf_file = pick($db_conf_file, "${cfssl::conf_dir}/db.conf")
    $_ca_file           = pick($ca_file, "${cfssl::conf_dir}/ca/ca.pem")
    $_responses_file    = pick($responses_file, "${cfssl::ocsp_dir}/${safe_title}.ocsp")

    ensure_packages(['python3-pymysql', 'python3-cryptography'])
    ensure_resource('file', '/usr/local/sbin/cfssl-ocsprefresh', {
                      ensure => file,
                      mode   => '0550',
                      source => 'puppet:///modules/cfssl/cfssl_ocsprefresh.py'})

    # create an empty response file the ocsp_responder can start
    file{ $_responses_file:
        ensure => file,
        owner  => 'root',
        group  => 'root',
    }
    if ($key_content and !$cert_content) or ($cert_content and !$key_content) {
        fail('you must provide either both or neither key/cert_content')
    } elsif $key_content and $cert_content {

        file {$cert_path:
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $cert_content,
            notify  => Service[$serve_service],
            before  => Systemd::Timer::Job[$refresh_timer],
        }
        file {$key_path:
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
            content   => $key_content,
            notify    => Service[$serve_service],
            before    => Systemd::Timer::Job[$refresh_timer],
        }
    } else {
        cfssl::cert{$safe_cert_name:
            common_name   => $common_name,
            label         => $safe_title,
            hosts         => $additional_names,
            profile       => 'ocsp',
            outdir        => $outdir,
            signer_config => {'config_file' => $cfssl::client::conf_file},
            tls_cert      => $facts['puppet_config']['hostcert'],
            tls_key       => $facts['puppet_config']['hostprivkey'],
            notify        => Service[$serve_service],
            before        => Systemd::Timer::Job[$refresh_timer],
        }
    }
    $update = $ocsprefresh_update ? {
        true    => '--update',
        default => '',
    }
    $refresh_command = @("CMD"/L)
        /usr/local/sbin/cfssl-ocsprefresh ${update} \
        --responder-cert ${cert_path} --responder-key ${key_path} \
        --ca-file ${_ca_file} --responses-file ${_responses_file} \
        --dbconfig ${_db_conf_file} \
        --restart-service '${serve_service}' ${safe_title} \
        | CMD

    systemd::service{$serve_service:
        ensure  => present,
        content => template('cfssl/cfssl-ocspserve.service.erb'),
        restart => true,
    }
    systemd::timer::job{$refresh_timer:
        ensure      => present,
        description => "OCSP Refresh job - ${title}",
        user        => 'root',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
        command     => $refresh_command,
    }
}
