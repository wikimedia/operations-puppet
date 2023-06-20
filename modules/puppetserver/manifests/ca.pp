# SPDX-License-Identifier: Apache-2.0
# @summary configure the puppetserver CA
# @param enable indicate if the ca is enable
# @param intermediate_ca configure puppet Ca with an intermediate CA
# @param ca_public_key location of the ihntermediate ca content
# @param ca_crl location of the ihntermediate crl content
# @param ca_private_key the content of the W
class puppetserver::ca (
    Boolean                      $enable          = true,
    Boolean                      $intermediate_ca = false,
    Optional[Stdlib::Filesource] $ca_public_key   = undef,
    Optional[Stdlib::Filesource] $ca_crl          = undef,
    Optional[Sensitive]          $ca_private_key  = undef,
) {
    if $intermediate_ca and [$ca_public_key, $ca_crl, $ca_private_key].any |$item| { $item =~ Undef } {
        alert("you must set all \$ca_public_key, \$ca_crl, \$ca_private_key when using \$intermediate_ca")
    }
    $base_content = 'puppetlabs.trapperkeeper.services.watcher.filesystem-watch-service/filesystem-watch-service'
    $enable_ca = 'puppetlabs.services.ca.certificate-authority-service/certificate-authority-service'
    $disable_ca = 'puppetlabs.services.ca.certificate-authority-disabled-service/certificate-authority-disabled-service'
    $content = $enable.bool2str(
        [$base_content, $enable_ca].join("\n"),
        [base_content, $disable_ca].join("\n")
    )
    file { "${puppetserver::bootstap_config_dir}/ca.cfg":
        ensure  => file,
        content => $content,
        before  => Service['puppetserver'],
    }
    $custom_ca_dir = "${puppetserver::config_dir}/puppetserver/custom_ca"
    $ca_file = "${custom_ca_dir}/ca.pem"
    $key_file = "${custom_ca_dir}/ca.key"
    $crl_file = "${custom_ca_dir}/crl.pem"

    # TODO: we need to ensure we mask puppetserver before importing the ca
    if $intermediate_ca {
        file {
            default:
                ensure => file,
                owner  => $puppetserver::owner,
                mode   => '0400',
                before => Exec['import intermidiate CA file'];
            $custom_ca_dir:
                ensure => directory;
            $ca_file:
                source => $ca_public_key;
            $key_file:
                content => $ca_private_key;
            $crl_file:
                source => $ca_crl;
        }
        $command = @("COMMAND"/L)
        /usr/bin/puppetserver ca import \
         --cert-bundle ${ca_file} \
         --private-key ${key_file} \
         --crl-chain ${crl_file}
        |- COMMAND
        exec{'import intermidiate CA file':
            command => $command,
            creates => "${puppetserver::config_dir}/puppetserver/ca",
            before  => Service['puppetserver'],
        }
    }
}
