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
# @param maintenance_jobs this parameter controls where maintenance jobs run e.g. ocsp generation cleaning expired certs
# @param $client_ca_source the CA bundle to use for TLS client auth connections
# @param default_nets a array of networks used by the multirootca as an ACL.  Access is configured
#   via apache so this config is not useful and should be left at the default
# @param default_auth_keys a Hash of default_auth_keys
# @param default_profiles a Hash of signing default_profiles
# @param intermediates a list of intermediate CN's to create
class profile::pki::multirootca (
    String                        $vhost              = lookup('profile::pki::multirootca::vhost'),
    Cfssl::DB_driver              $db_driver          = lookup('profile::pki::multirootca::db_driver'),
    String                        $db_user            = lookup('profile::pki::multirootca::db_user'),
    Sensitive[String[1]]          $db_pass            = lookup('profile::pki::multirootca::db_pass'),
    String                        $db_name            = lookup('profile::pki::multirootca::db_name'),
    Stdlib::Host                  $db_host            = lookup('profile::pki::multirootca::db_host'),
    String                        $root_ca_cn         = lookup('profile::pki::multirootca::root_ca_cn'),
    String                        $root_ca_cert       = lookup('profile::pki::multirootca::root_ca_cert'),
    String                        $root_ocsp_cert     = lookup('profile::pki::multirootca::root_ocsp_cert'),
    String                        $root_ocsp_key      = lookup('profile::pki::multirootca::root_ocsp_key'),
    Stdlib::Port                  $root_ocsp_port     = lookup('profile::pki::multirootca::root_ocsp_port'),
    Boolean                       $enable_client_auth = lookup('profile::pki::multirootca::enable_client_auth'),
    Stdlib::Filesource            $client_ca_source   = lookup('profile::pki::multirootca::client_ca_source'),
    Boolean                       $enable_monitoring  = lookup('profile::pki::multirootca::enable_monitoring'),
    Boolean                       $maintenance_jobs   = lookup('profile::pki::multirootca::maintenance_jobs'),
    Array[Cfssl::Usage]           $default_usages     = lookup('profile::pki::multirootca::default_usages'),
    Array[Stdlib::IP::Address]    $default_nets       = lookup('profile::pki::multirootca::default_nets'),
    Hash[String, Cfssl::Auth_key] $default_auth_keys  = lookup('profile::pki::multirootca::default_auth_keys'),
    Hash[String, Cfssl::Profile]  $default_profiles   = lookup('profile::pki::multirootca::default_profiles'),
    Hash[String, Hash]            $intermediates      = lookup('profile::pki::multirootca::intermediates'),

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
    $check_command_base = '/usr/local/sbin/cfssl-certs check -l'
    $ensure_monitoring = $enable_monitoring ? {
        true    => present,
        default => absent,
    }

    wmflib::dir::mkdir_p($bundle_dir)

    # Make the puppet CA available for download
    file {"${bundle_dir}/Puppet_Internal_CA.pem.pem":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => $facts['puppet_config']['localcacert'],
    }

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
        listen_port        => $root_ocsp_port,
        db_conf_file       => $db_conf_file,
        ca_file            => $root_ca_file,
        key_content        => Sensitive(secret($root_ocsp_key)),
        cert_content       => file($root_ocsp_cert),
        ocsprefresh_update => $maintenance_jobs,
        require            => Service[$multirootca_service],
    }

    # Create Signers
    $signers = $intermediates.reduce({}) |$memo, $value| {
        $intermediate    = $value[0]
        $config          = $value[1]
        $safe_title      = $intermediate.regsubst('\W', '_', 'G')
        $profiles        = pick($config['profiles'], $default_profiles)
        $auth_keys       = pick($config['auth_keys'], $default_auth_keys)
        $nets            = pick($config['nets'], $default_nets)
        $_default_usages = pick($config['default_usages'], $default_usages)
        $ca_key_file     = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}-key.pem"
        $ca_file         = "${cfssl::signer_dir}/${safe_title}/ca/${safe_title}.pem"
        $key_content     = "pki/intermediates/${intermediate}.pem"
        $cert_content    ="profile/pki/intermediates/${intermediate}.pem"
        $int_ca_content  = file($cert_content)

        cfssl::signer {$intermediate:
            profiles         => $profiles,
            ca_key_file      => $ca_key_file,
            ca_file          => $ca_file,
            ca_key_content   => Sensitive(secret($key_content)),
            ca_cert_content  => $int_ca_content,
            auth_keys        => $auth_keys,
            default_crl_url  => "${crl_base_url}/${safe_title}",
            default_ocsp_url => "${ocsp_base_url}/${safe_title}",
            serve_service    => $multirootca_service,
            db_conf_file     => $db_conf_file,
            manage_db        => false,
            manage_services  => false,
        }

        cfssl::ocsp{$intermediate:
            listen_port        => $config['ocsp_port'],
            db_conf_file       => $db_conf_file,
            ca_file            => $ca_file,
            ocsprefresh_update => $maintenance_jobs,
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
        modules => ['proxy_http', 'ssl', 'headers']
    }
    # TODO: probably replace this with acmechief
    $tls_termination_cert = $facts['puppet_config']['hostcert']
    $tls_termination_key = $facts['puppet_config']['hostprivkey']
    $tls_termination_chain = $facts['puppet_config']['localcacert']
    $ssl_settings   = ssl_ciphersuite('apache', 'strong', true)
    $client_auth_ca_file = '/etc/ssl/localcerts/multiroot_ca.pem'
    file{$client_auth_ca_file:
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => $client_ca_source,
        notify => Service['apache2'],
    }

    httpd::site{$vhost:
        ensure  => present,
        content => template('profile/pki/multirootca/vhost.conf.erb')
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
    systemd::timer::job {'cfssl-gc-expired-certs':
        ensure      => $maintenance_jobs.bool2str('present', 'absent'),
        description => 'Delete expired Certificates from the cfssl DB',
        user        => 'root',
        command     => '/usr/local/sbin/cfssl-certs clean',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => 'hourly'},
    }
}
