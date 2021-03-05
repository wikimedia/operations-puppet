# @param vhost the vhost to use for the crl/ocsp responder
# @param db_driver The db driver to use
# @param db_user The db user to use
# @param db_pass The db pass to use
# @param db_name The db name to use
# @param db_host The db host to use
# @param root_ca_content the content of the root CA public key as a string passed to the file command
# @param root_ca_cn The CN of the root ca used for creating the ocsp responder
# @param root_ocsp_cert The Root CA ocsp signing certificate as a string passed to the file command
# @param root_ocsp_key The Root CA ocsp signing key as a string passed to secret
# @param root_ocsp_port the ocsp listening port
# @param root_ca_cn The CN of the root ca used for creating the ocsp responder
# @param default_auth_keys a Hash of default_auth_keys
# @param default_profiles a Hash of signing default_profiles
# @param intermediates a list of intermediate CN's to create
class profile::pki::multirooca (
    String                        $vhost             = lookup('profile::pki::multirooca::vhost'),
    Cfssl::DB_driver              $db_driver         = lookup('profile::pki::multirooca::db_driver'),
    String                        $db_user           = lookup('profile::pki::multirooca::db_user'),
    Sensitive[String[1]]          $db_pass           = lookup('profile::pki::multirooca::db_pass'),
    String                        $db_name           = lookup('profile::pki::multirooca::db_name'),
    Stdlib::Host                  $db_host           = lookup('profile::pki::multirooca::db_host'),
    String                        $root_ca_cn        = lookup('profile::pki::multirooca::root_ca_cn'),
    String                        $root_ca_cert      = lookup('profile::pki::multirooca::root_ca_cert'),
    String                        $root_ocsp_cert    = lookup('profile::pki::multirooca::root_ocsp_cert'),
    String                        $root_ocsp_key     = lookup('profile::pki::multirooca::root_ocsp_key'),
    Stdlib::Port                  $root_ocsp_port    = lookup('profile::pki::multirooca::root_ocsp_port'),
    Hash[String, Cfssl::Profile]  $default_auth_keys = lookup('profile::pki::multirooca::default_auth_keys'),
    Hash[String, Cfssl::Profile]  $default_profiles  = lookup('profile::pki::multirooca::default_profiles'),
    Hash[String, Cfssl::Profile]  $default_nets      = lookup('profile::pki::multirooca::default_nets'),
    Hash[String, Hash]            $intermediates     = lookup('profile::pki::multirooca::intermediates'),

) {
    class {'cfssl': }

    $crl_base_url = "http://${vhost}/crl"
    $ocsp_base_url = "http://${vhost}/ocsp"
    $db_conf_file = "${cfssl::conf_dir}/db.conf"
    $root_ca_file = "${cfssl::ssl_dir}/${root_ca_cn.regsubst('\W', '_', 'G')}.pem"
    $multirootca_service = 'cfssl-multirootca'

    cfssl::db{'multirooca-db':
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

    file {$root_ca_file:
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => file($root_ca_cert),
    }
    # Root CA OCSP responder
    cfssl::ocsp{$root_ca_cn:
        listen_port  => $root_ocsp_port,
        db_conf_file => "${db_conf_file}.json",
        ca_file      => $root_ca_file,
        key_content  => Sensitive(secret($root_ocsp_key)),
        cert_content => file($root_ocsp_cert),
    }

    # Create Signers
    $signers = $intermediates.reduce({}) |$memo, $value| {
        $intermediate = $value[0]
        $config       = $value[1]
        $safe_title   = $intermediate.regsubst('\W', '_', 'G')
        $profiles     = pick($config['profiles'], $default_profiles)
        $auth_keys    = pick($config['auth_keys'], $default_auth_keys)
        $nets         = pick($config['nets'], $default_nets)
        $ca_key_file  = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}-key.pem"
        $ca_file      = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}.pem"

        cfssl::signer {$intermediate:
            profiles         => $profiles,
            ca_key_file      => $ca_key_file,
            ca_file          => $ca_file,
            ca_key_content   => Sensitive(secret($config['key_content'])),
            ca_cert_content  => file($config['cert_content']),
            ca_bundle_file   => "${cfssl::signer_dir}/WMF_root_CA/ca/ca.pem",
            auth_keys        => $auth_keys,
            default_crl_url  => "${crl_base_url}/${safe_title}",
            default_ocsp_url => "${ocsp_base_url}/${safe_title}",
            serve_service    => $multirootca_service,
            db_conf_file     => $db_conf_file,
            manage_db        => false,
            manage_services  => false,
        }

        cfssl::ocsp{$intermediate:
            listen_port  => $config['ocsp_port'],
            db_conf_file => "${db_conf_file}.json",
            ca_file      => $ca_file,
        }
        $memo + {
            $safe_title => {
                'private'     => $ca_key_file,
                'certificate' => $ca_file,
                'config'      => "${cfssl::signer_dir}/${safe_title}/cfssl.conf",
                'dbconfig'    => $db_conf_file,
                'nets'        => $nets,
            }
        }
    }
    class {'cfssl::multirootca':
        tls_cert => $facts['puppet_config']['hostcert'],
        tls_key  => $facts['puppet_config']['hostprivkey'],
        signers  => $signers,
    }
    ferm::service{'multirootca':
        proto  => 'tcp',
        port   => '8888',
        srange => '$DOMAIN_NETWORKS',
    }

    # CRL and OCSP responder
    class {'httpd':
        modules => ['proxy_http']
    }
    httpd::site{$vhost:
        ensure  => present,
        content => template('profile/pki/multirooca/ocsp_responder.conf.erb')
    }
    ferm::service{'csr_and_ocsp_responder':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
