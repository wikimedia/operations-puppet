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
# @param $enable_client_auth if true make sure connections authenticate with TLS client auth
# @param $client_ca_source the CA bundle to use for TLS client auth connections
# @param default_nets a array of networks used by the multirooca as an ACL.  Access is configured
#   via apache so this config is not useful and should be left at the default
# @param default_auth_keys a Hash of default_auth_keys
# @param default_profiles a Hash of signing default_profiles
# @param intermediates a list of intermediate CN's to create
class profile::pki::multirooca (
    String                        $vhost              = lookup('profile::pki::multirooca::vhost'),
    Cfssl::DB_driver              $db_driver          = lookup('profile::pki::multirooca::db_driver'),
    String                        $db_user            = lookup('profile::pki::multirooca::db_user'),
    Sensitive[String[1]]          $db_pass            = lookup('profile::pki::multirooca::db_pass'),
    String                        $db_name            = lookup('profile::pki::multirooca::db_name'),
    Stdlib::Host                  $db_host            = lookup('profile::pki::multirooca::db_host'),
    String                        $root_ca_cn         = lookup('profile::pki::multirooca::root_ca_cn'),
    String                        $root_ca_cert       = lookup('profile::pki::multirooca::root_ca_cert'),
    String                        $root_ocsp_cert     = lookup('profile::pki::multirooca::root_ocsp_cert'),
    String                        $root_ocsp_key      = lookup('profile::pki::multirooca::root_ocsp_key'),
    Stdlib::Port                  $root_ocsp_port     = lookup('profile::pki::multirooca::root_ocsp_port'),
    Boolean                       $enable_client_auth = lookup('profile::pki::multirooca::enable_client_auth'),
    Stdlib::Filesource            $client_ca_source   = lookup('profile::pki::multirooca::client_ca_source'),
    Array[Stdlib::IP::Address]    $default_nets       = lookup('profile::pki::multirooca::default_nets'),
    Hash[String, Cfssl::Auth_key] $default_auth_keys  = lookup('profile::pki::multirooca::default_auth_keys'),
    Hash[String, Cfssl::Profile]  $default_profiles   = lookup('profile::pki::multirooca::default_profiles'),
    Hash[String, Hash]            $intermediates      = lookup('profile::pki::multirooca::intermediates'),

) {
    # we need to include this as we use some of the variables
    include cfssl  # lint:ignore:wmf_styleguide

    $crl_base_url = "http://${vhost}/crl"
    $ocsp_base_url = "http://${vhost}/ocsp"
    $db_conf_file = "${cfssl::conf_dir}/db.conf"
    $root_ca_file = "${cfssl::ssl_dir}/${root_ca_cn.regsubst('\W', '_', 'G')}.pem"
    $multirootca_service = 'cfssl-multirootca'
    $document_root = '/srv/cfssl'
    $bundle_dir = "${document_root}/bundles"

    wmflib::dir::mkdir_p($bundle_dir)

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

    $root_ca_content = file($root_ca_cert)
    file {$root_ca_file:
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => $root_ca_content,
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
        $intermediate   = $value[0]
        $config         = $value[1]
        $safe_title     = $intermediate.regsubst('\W', '_', 'G')
        $profiles       = pick($config['profiles'], $default_profiles)
        $auth_keys      = pick($config['auth_keys'], $default_auth_keys)
        $nets           = pick($config['nets'], $default_nets)
        $ca_key_file    = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}-key.pem"
        $ca_file        = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}.pem"
        $int_ca_content = file($config['cert_content'])

        cfssl::signer {$intermediate:
            profiles         => $profiles,
            ca_key_file      => $ca_key_file,
            ca_file          => $ca_file,
            ca_key_content   => Sensitive(secret($config['key_content'])),
            ca_cert_content  => $int_ca_content,
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
        # Create a bundle file with the intermediate and root certs
        file {"${bundle_dir}/${safe_title}.pem":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "${root_ca_content}${int_ca_content}",
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
        signers  => $signers,
    }
    class { 'sslcert::dhparam': }
    # CRL and OCSP responder
    class {'httpd':
        modules => ['proxy_http', 'ssl']
    }
    # TODO: probably replace this with acmechief
    $tls_termination_cert = $facts['puppet_config']['hostcert']
    $tls_termination_key = $facts['puppet_config']['hostcert']
    $tls_termination_chain = $facts['puppet_config']['localcacert']
    $ssl_settings   = ssl_ciphersuite('apache', 'strong', true)
    $client_auth_ca_file = '/etc/ssl/localcerts/multiroot_ca.pem'
    file{$client_auth_ca_file:
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => $client_ca_source,
    }

    httpd::site{$vhost:
        ensure  => present,
        content => template('profile/pki/multirooca/vhost.conf.erb')
    }
    ferm::service{'csr_and_ocsp_responder':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
    ferm::service{'multirootca tls termination':
        proto  => 'tcp',
        port   => '443',
        srange => '$DOMAIN_NETWORKS',
    }
}
