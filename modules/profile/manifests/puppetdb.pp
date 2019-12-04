class profile::puppetdb(
    Array[Stdlib::Host]                  $prometheus_nodes  = lookup('prometheus_nodes'),
    Hash[String, Puppetmaster::Backends] $puppetmasters     = lookup('puppetmaster::servers'),
    Stdlib::Host                         $master            = lookup('profile::puppetdb::master'),
    String                               $jvm_opts          = lookup('profile::puppetdb::jvm_opts'),
    Boolean                              $elk_logging       = lookup('profile::puppetdb::elk_logging'),
    Boolean                              $filter_job_id     = lookup('profile::puppetdb::filter_job_id'),
    Stdlib::Unixpath                     $ca_path           = lookup('profile::puppetdb::ca_path'),
    String                               $puppetboard_hosts = lookup('profile::puppetdb::puppetboard_hosts'),
    # default value of undef still needs to be in the manifest untill we move to hiera 5
    Optional[Stdlib::Unixpath]           $ssldir            = lookup('profile::puppetdb::ssldir',
                                                                    {'default_value' => undef}),
) {

    # Prometheus JMX agent for the Puppetdb's JVM
    $jmx_exporter_config_file = '/etc/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml'
    $prometheus_jmx_exporter_port = 9400
    $prometheus_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # The JVM heap size has been raised to 6G for T170740
    class { '::puppetmaster::puppetdb':
        master        => $master,
        jvm_opts      => "${jvm_opts} ${prometheus_java_opts}",
        ssldir        => $ssldir,
        ca_path       => $ca_path,
        filter_job_id => $filter_job_id
    }

    # Export JMX metrics to prometheus
    profile::prometheus::jmx_exporter { "puppetdb_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        content          => file('profile/puppetmaster/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml'),
    }

    # Firewall rules

    # Only the TLS-terminating nginx proxy will be exposed
    $puppetmasters_ferm = inline_template('<%= @puppetmasters.values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')

    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }

    ferm::service { 'puppetdb-cumin':
        proto  => 'tcp',
        port   => 443,
        srange => '$CUMIN_MASTERS',
    }

    if !empty($puppetboard_hosts) {
        ferm::service { 'puppetboard':
            proto  => 'tcp',
            port   => 443,
            srange => "@resolve((${puppetboard_hosts}))",
        }
    }

    if $elk_logging {
        # Ship PuppetDB logs to ELK
        rsyslog::input::file { 'puppetdb':
            path => '/var/log/puppetdb/puppetdb.log',
        }
    }
    include profile::puppetdb::microservice
}
