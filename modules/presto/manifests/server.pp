# Class: presto::server
#
# Sets up a Presto server, either worker or coordinator or both, depending on settings.
# NOTE: Do not include this class on a node that has presto::client.
#
# == Parameters
# [*enabled*]
#   If the Presto server should be running or not.
#
# [*config_properties*]
#   Properties to render into config.properties.
#
# [*node_properties*]
#   Properties to render into node.properties.
#
# [*log_properties*]
#   Properties to render into log.properties.
#
# [*catalogs*]
#   Hash of catalog names to properties.
#   Each entry in this hash will be rendered into a properties file in the
#   /etc/presto/catalogs directory.
#
# [*heap_max*]
#   Max JVM heapsize of Presto server; will be rendered into jvm.properties.
#
class presto::server(
    Boolean $enabled           = true,
    Hash    $config_properties = {},
    Hash    $node_properties   = {},
    Hash    $log_properties    = {},
    Hash    $catalogs          = {},
    String  $heap_max          = '2G',
) {
    if defined(Class['::presto::client']) {
        fail('Class presto::client and presto::server should not be included on the same node; presto::server will include the presto-cli package itself.')
    }

    require_package('presto-cli')
    require_package('presto-server')

    $default_config_properties = {
        # lint:ignore:quoted_booleans
        'coordinator'                        => 'true',
        'node-scheduler.include-coordinator' => 'true',
        'discovery-server.enabled'           => 'true',
        # lint:endignore
        # Use non-default http port to avoid conflicts with commonly used 8080
        'http-server.http.port'              => '8280',
        'jmx.rmiregistry.port'               => '8279',
        'discovery.uri'                      => 'http://localhost:8280',
    }

    $default_node_properties = {
        'node.environment' => 'test',
        'node.id'          => '1001',
        'node.data-dir'    => '/var/lib/presto',
    }


    $default_log_properties = {
        'com.facebook.presto' => 'INFO',
    }


    $presto_config_properties = merge($default_config_properties, $config_properties)
    presto::properties { 'config':
        properties => $presto_config_properties,
    }

    $presto_node_properties = merge($default_node_properties, $node_properties)
    presto::properties { 'node':
        properties => $presto_node_properties,
    }

    $presto_log_properties = merge($default_log_properties, $log_properties)
    presto::properties { 'log':
        properties => $presto_log_properties,
    }

    file { '/etc/presto/jvm.config':
        content => template('presto/jvm.config.erb')
    }

    # Ensure presto catalog properties files are created for each
    # defined catalog. Using ensure_resources allows us to create
    # an entry for each defined catalog without having to
    # manually declare each one.
    ensure_resources('::presto::catalog', $catalogs)


    # Make sure the $data_dir exists
    $data_dir = $presto_node_properties['node.data-dir']
    if !defined(File[$data_dir]) {
        file { $data_dir:
            ensure  => 'directory',
            owner   => 'presto',
            group   => 'presto',
            mode    => '0755',
            require => Package['presto-server'],
            before  => Service['presto-server'],
        }
    }

    # By default Presto writes its logs out to $data_dir/log.
    # Symlink /var/log/presto to this location.
    if !defined(File['/var/log/presto']) {
        file { '/var/log/presto':
            ensure  => "${data_dir}/var/log",
            require => File[$data_dir],
        }
    }


    # Output Presto server logs to $data_dir/var/log/server.log and
    # reotate the server.log file.  http-request.log is rotated and managed
    # by Presto itself.
    logrotate::conf { 'presto-server':
        content => template('presto/logrotate.conf.erb'),
        require => Package['presto-server'],
    }
    rsyslog::conf { 'presto-server':
        content => template('presto/rsyslog.conf.erb'),
        require => Logrotate::Conf['presto-server'],
    }


    $service_ensure = $enabled ? {
        false   => 'stopped',
        default => 'running',
    }

    # Start the Presto server.
    # Presto will not auto restart on config changes.
    service { 'presto-server':
        ensure  => $service_ensure,
        require => [
            Presto::Properties['config'],
            Presto::Properties['node'],
            Presto::Properties['log'],
            File['/etc/presto/jvm.config'],
            File['/var/log/presto'],
            Rsyslog::Conf['presto-server'],
        ],
    }
}
