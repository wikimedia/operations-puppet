# == Class profile::presto::server
#
# Sets up a presto server in a presto cluster.
# By default this node will be set up as a worker node.  To enable the
# coordinator or discovery, provide appropriate settings in $config_properties.
#
# See also: https://prestodb.io/docs/current/installation/deployment.html
#
# == Parameters
#
# [*cluster_name*]
#   Name of the Presto cluster.  This will be used as the default node.environment.
#
# [*discovery_uri*]
#   URI to the Presto discovery server.
#
# [*node_properties*]
#   Specific node.properties settings. This profile attempts to use sane defaults.
#   Only set this if you need to override them.  Note that node.id will be
#   set automatically by the presto::server module class based on the current node's
#   $::fqdn.
#
# [*config_properties*]
#   Specific config.properties settings. This profile attempts to use sane defaults.
#   Only set this if you need to override them.
#
# [*log_properties*]
#   Specific log.properties settings.
#
# [*heap_max*]
#   -Xmx argument. Default: 2G
#
# [*generate_certificate*]
#   Use the pki::get_cert function to generate a certificate for TLS authentication,
#   using the discovery CA, as opposed to using the Puppet CA certificates. If this
#   option is enabled, a certificate will be generated using the host's $::fqdn.
#   Default: false
#
# [*ssl_certnames*]
#   Optional array of SubjectAltNames that should be added to a certificate generated
#   by the pki::get_cert function. This is only used if generate_certificates is true.
#   Default: []
#
#  [*presto_clusters_secrets*]
#    Hash of available/configured Presto clusters and their secret properties,
#    like passwords, etc..
#    The following values will be checked in the hash table only if TLS/Kerberos
#    configs are enabled (see in the code for the exact values).
#      - 'ssl_keystore_password'
#      - 'ssl_trustore_password'
#    Default: {}
#
class profile::presto::server(
    String        $cluster_name         = lookup('profile::presto::cluster_name'),
    String        $discovery_uri        = lookup('profile::presto::discovery_uri'),
    Hash          $node_properties      = lookup('profile::presto::server::node_properties', { 'default_value' => {} }),
    Hash          $config_properties    = lookup('profile::presto::server::config_properties', { 'default_value' => {} }),
    Hash          $catalogs             = lookup('profile::presto::server::catalogs', { 'default_value' => {} }),
    Hash          $log_properties       = lookup('profile::presto::server::log_properties', { 'default_value' => {} }),
    String        $heap_max             = lookup('profile::presto::server::heap_max', { 'default_value' => '2G' }),
    String        $ferm_srange          = lookup('profile::presto::server::ferm_srange', { 'default_value' => '$DOMAIN_NETWORKS' }),
    Array[String] $ssl_certnames        = lookup('profile::presto::server::ssl_certnames', { 'default_value' => [] }),
    Boolean       $generate_certificate = lookup('profile::presto::server::generate_certificate', { 'default_value' => false }),
    Boolean       $use_kerberos         = lookup('profile::presto::use_kerberos', { 'default_value' => true }),
    Boolean       $monitoring_enabled   = lookup('profile::presto::monitoring_enabled', { 'default_value' => false }),
    Optional[Hash[String, Hash[String, String]]] $presto_clusters_secrets = lookup('presto_clusters_secrets', { 'default_value' => {} }),
) {

    $default_node_properties = {
        'node.enviroment'              => $cluster_name,
        'node.data-dir'                => '/srv/presto',
        'node.internal-address-source' => 'FQDN',
    }

    $default_config_properties = {
        'jmx.rmiregistry.port'               => '8279',
        'discovery.uri'                      => $discovery_uri,

        # flat will try to schedule splits on the host where the data is located by reserving
        # 50% of the work queue for local splits. It is recommended to use flat for clusters
        # where distributed storage runs on the same nodes as Presto workers.
        # You should change this if your Presto cluster is not colocated with storage.
        'node-scheduler.network-topology'    => 'flat',

        # Enables accessing the Presto UI over http. Access it as follows:
        # ssh -NL 8280:an-test-coord1001.eqiad.wmnet:8280 an-test-coord1001.eqiad.wmnet
        # (for the test cluster, for the production cluster use an-coord1001).
        # Then visit http://localhost:8280 (which should redirect to http://localhost:8280/ui/)
        'http-server.http.port'              => '8280',
        'http-server.http.enabled'           => true,
    }

    if $use_kerberos {
        $hostname_suffix = $::realm ? {
            'labs'  => '.eqiad.wmflabs',
            default => "${::site}.wmnet",
        }

        $keystore_password = $presto_clusters_secrets[$cluster_name]['ssl_keystore_password']
        $ssl_keystore_path = '/etc/presto/ssl/server.p12'
        $ssl_truststore_path = '/etc/ssl/certs/java/cacerts'
        $ssl_truststore_password = 'changeit'

        if $generate_certificate {
            # Generate a certificate for each presto server. These will be used to secure traffic between
            # 1) the clients and the co-ordinator and 2) between each server in the cluster
            # The co-ordinator will use several SubJectAltNames in order to support DNS discovery
            $ssl_cert = profile::pki::get_cert('discovery', $facts['fqdn'], {
                'hosts'  => $ssl_certnames,
                'outdir' => '/etc/presto/ssl',
                'owner'  => 'presto',
                notify   => Sslcert::X509_to_pkcs12['presto_keystore'],
                require  => Package['presto-server'],
                }
            )
            sslcert::x509_to_pkcs12 { 'presto_keystore' :
                owner       => 'presto',
                group       => 'presto',
                public_key  => $ssl_cert['cert'],
                private_key => $ssl_cert['key'],
                certfile    => $ssl_cert['ca'],
                outfile     => $ssl_keystore_path,
                password    => $keystore_password,
                require     => Package['presto-server'],
                notify      => Service['presto-server'],
            }
        } else {
            # TODO: consider using profile::pki::get_cert
            puppet::expose_agent_certs{ '/etc/presto':
                user         => 'root',
                group        => 'presto',
                provide_p12  => true,
                provide_pem  => false,
                p12_password => $keystore_password,
                require      => Package['presto-server'],
            }
        }

        file { '/usr/local/bin/presto':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('profile/presto/presto_client_ssl_kerberos.erb'),
            require => Package['presto-server'],
        }
    }

    if $presto_clusters_secrets[$cluster_name] {
        $ssl_keystore_password = $presto_clusters_secrets[$cluster_name]['ssl_keystore_password']
        $default_ssl_properties = {
            'http-server.https.keystore.path' => $ssl_keystore_path,
            'http-server.https.keystore.key' => $ssl_keystore_password,
            'internal-communication.https.required' => true,
            'internal-communication.https.keystore.path' => $ssl_keystore_path,
            'internal-communication.https.keystore.key' => $ssl_keystore_password,
            'internal-communication.https.trust-store-path' => '/etc/ssl/certs/java/cacerts',
            'internal-communication.https.trust-store-password' => 'changeit',
            'http-server.https.port' => '8281',
            'http-server.https.enabled' => true,
        }
    } else {
        $default_ssl_properties = {}
    }

    if $use_kerberos {
        $default_kerberos_properties = {
            'internal-communication.kerberos.enabled' => true,
            'http-server.authentication.type' => 'KERBEROS',
            'http.authentication.krb5.config' => '/etc/krb5.conf',
            'http.server.authentication.krb5.keytab' => '/etc/security/keytabs/presto/presto.keytab',
            'http.server.authentication.krb5.service-name' => 'presto',
        }
    } else {
        $default_kerberos_properties = {}
    }

    # Merge in any overrides for properties
    $_node_properties = $default_node_properties + $node_properties
    $_config_properties = $default_config_properties + $config_properties + $default_ssl_properties + $default_kerberos_properties

    if $monitoring_enabled {
        include ::profile::presto::monitoring::server
        $jmx_agent_port = $::profile::presto::monitoring::server::prometheus_jmx_exporter_server_port
        $jmx_agent_config_file = $::profile::presto::monitoring::server::jmx_exporter_config_file
        $extra_jvm_configs = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=[::]:${jmx_agent_port}:${jmx_agent_config_file}"

        nrpe::monitor_service { 'presto-server':
            description   => 'Presto Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "com.facebook.presto.server.PrestoServer"',
            contact_group => 'analytics',
            require       => Class['presto::server'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Presto/Administration#Presto_server_down',
        }
    } else {
        $extra_jvm_configs = undef
    }

    class { '::presto::server':
        node_properties   => $_node_properties,
        config_properties => $_config_properties,
        log_properties    => $log_properties,
        catalogs          => $catalogs,
        heap_max          => $heap_max,
        extra_jvm_configs => $extra_jvm_configs,
    }

    if $presto_clusters_secrets[$cluster_name] {
        ferm::service{ 'presto-https':
            proto  => 'tcp',
            port   => $_config_properties['http-server.https.port'],
            srange => $ferm_srange,
        }
    } else {
        ferm::service{ 'presto-http':
            proto  => 'tcp',
            port   => $_config_properties['http-server.http.port'],
            srange => $ferm_srange,
        }
    }

    ferm::service{ 'presto-jmx-rmiregistry':
        proto  => 'tcp',
        port   => $_config_properties['jmx.rmiregistry.port'],
        srange => $ferm_srange,
    }
}
