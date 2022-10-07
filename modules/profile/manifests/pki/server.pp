# SPDX-License-Identifier: Apache-2.0
# @summary configure a PKI sevrver
# @param ca_key_content The location of the private key as used by the secret function (Required)
# @param ca_cert_content The location of the public cert as used by the file function (Required)
# @param names The certificate authority names used for intermediates
# @param key_params The key algorithm and size used for intermediates
# @param gen_csr if true genrate a CSR.  this is only needed when bootstrapping
# @param default_profiles a Hash of signing default_profiles
# @param intermediates a list of intermediate CN's to create
class profile::pki::server(
    String                        $vhost            = lookup('profile::pki::server::vhost'),
    String                        $ca_key_content   = lookup('profile::pki::server::ca_key_content'),
    String                        $ca_cert_content  = lookup('profile::pki::server::ca_cert_content'),
    Array[Cfssl::Name]            $names            = lookup('profile::pki::server::names'),
    Cfssl::Key                    $key_params       = lookup('profile::pki::server::key_params'),
    Boolean                       $gen_csr          = lookup('profile::pki::server::gen_csr'),
    Cfssl::DB_driver              $db_driver        = lookup('profile::pki::server::db_driver'),
    String                        $db_user          = lookup('profile::pki::server::db_user'),
    Sensitive[String[1]]          $db_pass          = lookup('profile::pki::server::db_pass'),
    String                        $db_name          = lookup('profile::pki::server::db_name'),
    Stdlib::Host                  $db_host          = lookup('profile::pki::server::db_host'),
    Hash[String, Cfssl::Profile]  $root_ca_profiles = lookup('profile::pki::server::root_ca_profiles'),
    Hash[String, Cfssl::Profile]  $default_profiles = lookup('profile::pki::server::default_profiles'),
    Hash[String, Cfssl::Auth_key] $auth_keys        = lookup('profile::pki::server::auth_keys'),
    Hash[String, Hash]            $intermediates    = lookup('profile::pki::server::intermediates'),
) {
    $crl_base_url = "http://${vhost}/crl"
    $ocsp_base_url = "http://${vhost}/ocsp"
    # we need to include this as we use some of the variables
    include cfssl  # lint:ignore:wmf_styleguide
    $db_conf_file = "${cfssl::conf_dir}/db.conf"
    $multirootca_service = 'cfssl-multirootca'
    cfssl::db{'multirootca-db':
        driver         => $db_driver,
        username       => $db_user,
        password       => $db_pass,
        dbname         => $db_name,
        host           => $db_host,
        conf_file      => $db_conf_file,
        notify_service => $multirootca_service,
        python_config  => true,
        ssl_ca         => $facts['puppet_config']['localcacert'],
    }

    $_root_ca_profiles = $root_ca_profiles.empty? {
        true    => $default_profiles,
        default => $root_ca_profiles,
    }
    cfssl::signer {'WMF_root_CA':
        profiles         => $_root_ca_profiles,
        ca_key_content   => Sensitive(secret($ca_key_content)),
        ca_cert_content  => file($ca_cert_content),
        auth_keys        => $auth_keys,
        default_crl_url  => $crl_base_url,
        default_ocsp_url => $ocsp_base_url,
        serve_service    => $multirootca_service,
        db_conf_file     => $db_conf_file,
        manage_db        => false,
        manage_services  => false,
    }
    $signers = $intermediates.reduce({}) |$memo, $value| {

        $intermediate = $value[0]
        $config       = $value[1]
        $safe_title   = $intermediate.regsubst('\W', '_', 'G')
        $profiles     = pick($config['profiles'], $default_profiles)
        $_root_ca_profiles = $config.has_key('profiles') ? {
            true    => $config['profiles'],
            default => $default_profiles,
        }

        if 'key_content' in $config and 'cert_content' in $config {
            # Pull key material from puppet
            $ca_key_content  = Sensitive(secret($config['key_content']))
            $ca_cert_content = file($config['cert_content'])
            $ca_key_file     = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}-key.pem"
            $ca_file         = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}.pem"
        } else {
            # Generate key material on the fly
            cfssl::cert{$intermediate:
                key           => $key_params,
                names         => $names,
                signer_config => {'config_dir' => "${cfssl::signer_dir}/WMF_root_CA"},
                profile       => 'intermediate',
                require       => Cfssl::Signer['WMF_root_CA'],
                notify        => Service['cfssl-multirootca'],
            }
            $ca_key_content  = undef
            $ca_cert_content = undef
            $ca_key_file    = "${cfssl::ssl_dir}/${safe_title}/${safe_title}-key.pem"
            $ca_file        = "${cfssl::ssl_dir}/${safe_title}/${safe_title}.pem"
        }

        $crl_url = "${crl_base_url}/${safe_title}"
        $ocsp_url = "${ocsp_base_url}/${safe_title}"
        cfssl::signer {$intermediate:
            profiles         => $profiles,
            ca_key_file      => $ca_key_file,
            ca_file          => $ca_file,
            ca_key_content   => $ca_key_content,
            ca_cert_content  => $ca_cert_content,
            ca_bundle_file   => "${cfssl::signer_dir}/WMF_root_CA/ca/ca.pem",
            auth_keys        => $auth_keys,
            default_crl_url  => $crl_url,
            default_ocsp_url => $ocsp_url,
            serve_service    => $multirootca_service,
            db_conf_file     => $db_conf_file,
            manage_db        => false,
            manage_services  => false,
        }
        cfssl::ocsp{$intermediate:
            common_name      => 'pki.discovery.wmnet',
            additional_names => [$facts['fqdn']],
            listen_port      => $config['ocsp_port'],
            db_conf_file     => "${db_conf_file}.json",
            ca_file          => $ca_file,
        }
        $memo + {
            $safe_title => {
                'private'     => $ca_key_file,
                'certificate' => $ca_file,
                'config'      => "${cfssl::signer_dir}/${safe_title}/cfssl.conf",
                'dbconfig'    => $db_conf_file,
                'nets'        => $config['nets'],
            }
        }
    }
    class {'cfssl::multirootca':
        tls_cert => $facts['puppet_config']['hostcert'],
        tls_key  => $facts['puppet_config']['hostprivkey'],
        signers  => $signers,
    }

    class {'httpd':
        modules => ['proxy_http']
    }
    httpd::site{$vhost:
        ensure  => present,
        content => template('profile/pki/server/pki.discovery.wmnet.conf.erb')
    }
    ferm::service{'csr_and_ocsp_responder':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
    ferm::service{'multirootca':
        proto  => 'tcp',
        port   => '8888',
        srange => '$DOMAIN_NETWORKS',
    }
}
