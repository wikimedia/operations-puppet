class profile::puppetdb(
    String $master = hiera('profile::puppetdb::master'),
    Hash[String, Array[Hash]] $puppetmasters = hiera('puppetmaster::servers'),
    String $jvm_opts = hiera('profile::puppetdb::jvm_opts', '-Xmx4G'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    Optional[String] $ssldir = hiera('profile::puppetdb::ssldir', undef),
    Optional[String] $ca_path = hiera('profile::puppetdb::ca_path', undef),
    Optional[String] $puppetboard_hosts = hiera('profile::puppetdb::puppetboard_hosts', ''),
    Boolean $microservice_enabled = hiera('profile::puppetdb::microservice::enabled'),
    Integer $microservice_port = hiera('profile::puppetdb::microservice::port', 0),
    Integer $microservice_uwsgi_port = hiera('profile::puppetdb::microservice::uwsgi_port', 0),
    String $microservice_allowed_hosts = hiera('netmon_server', ''),
    Boolean $elk_logging = lookup('profile::puppetdb::rsyslog::elk', {'default_value' => false})
) {

    # Prometheus JMX agent for the Puppetdb's JVM
    $jmx_exporter_config_file = '/etc/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml'
    $prometheus_jmx_exporter_port = 9400
    $prometheus_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # The JVM heap size has been raised to 6G for T170740
    class { '::puppetmaster::puppetdb':
        master   => $master,
        jvm_opts => "${jvm_opts} ${prometheus_java_opts}",
        ssldir   => $ssldir,
        ca_path  => $ca_path,
    }

    # Export JMX metrics to prometheus
    profile::prometheus::jmx_exporter { "puppetdb_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/puppetmaster/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml',
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
            path => '/var/log/puppetlabs/puppetdb/puppetdb.log',
        }
    }

    if $microservice_enabled {
        $ssl_settings = ssl_ciphersuite('nginx', 'strong', true)

        nginx::site { 'puppetdb-microservice':
            ensure  => present,
            content => template('profile/puppetdb/nginx-puppetdb-microservice.conf.erb'),
        }

        file { '/srv/puppetdb-microservice.py':
            ensure => present,
            source => 'puppet:///modules/profile/puppetdb/puppetdb-microservice.py',
            owner  => 'root',
            mode   => '0644',
        }
        require_package('python3-flask')
        uwsgi::app { 'puppetdb-microservice':
            ensure   => present,
            settings => {
                uwsgi => {
                    'plugins'     => 'python3',
                    'socket'      => '/run/uwsgi/puppetdb-microservice.sock',
                    'file'        => '/srv/puppetdb-microservice.py',
                    'callable'    => 'app',
                    'http-socket' => "127.0.0.1:${microservice_uwsgi_port}",
                },

            },
        }
        ferm::service { 'puppetdb-microservice':
            ensure => present,
            proto  => 'tcp',
            port   => $microservice_port,
            srange => "@resolve((${microservice_allowed_hosts}))",
        }
    }
    else {
        nginx::site { 'puppetdb-microservice':
            ensure  => absent,
        }
        file { '/srv/puppetdb-microservice.py':
            ensure => absent,
        }
        uwsgi::app { 'puppetdb-microservice':
            ensure => absent,
        }
    }
}
