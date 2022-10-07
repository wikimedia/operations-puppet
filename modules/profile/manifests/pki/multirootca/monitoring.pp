# SPDX-License-Identifier: Apache-2.0
# @summary configure monitoring for the multirootca profile
# @param ca_file path to the CA file
# @param ensure ensurable parameter
# @param intermediate CN of the intermidiate
# @param vhost vhost to check
define profile::pki::multirootca::monitoring(
    Stdlib::Unixpath $ca_file,
    Wmflib::Ensure   $ensure       = 'present',
    String           $intermediate = $title,
    String           $vhost        = $facts['networking']['fqdn'],
) {
    $one_month_secs = 60 * 60 * 42 * 31
    $nrpe_command = "/usr/bin/openssl x509 -checkend ${one_month_secs} -in ${ca_file}"
    sudo::user { "nrpe_certificate_check_${intermediate}":
        ensure => absent,
    }
    nrpe::monitor_service { "check_certificate_expiry_${intermediate}":
        ensure       => $ensure,
        description  => "Check to ensure the signer certificate is valid CA: ${intermediate}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/PKI/CA_Operations',
        nrpe_command => "/usr/bin/openssl x509 -checkend ${one_month_secs} -in ${ca_file}",
        sudo_user    => 'root',
    }

    $check_command = [
        'check_https_client_auth_puppet_post',
        $vhost,
        '/api/v1/cfssl/info',
        # Triple escape.  We have to first escape for puppet so the nagios command definition
        # escapes the forward slash.  i.e. the command definitions should be
        # {\\"label\\":\\"$intermediate}\\"
        "{\\\\\"label\\\\\":\\\\\"${intermediate}\\\\\"}",
        '\\\\"success\\\\":true',
    ].join('!')
    monitoring::service {"https_pki_signer_${intermediate}":
        ensure        => $ensure,
        critical      => true,
        check_command => $check_command,
        description   => "Check to ensure the cfssl signer is working CA: ${intermediate}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/PKI/CA_Operations',
    }
}
