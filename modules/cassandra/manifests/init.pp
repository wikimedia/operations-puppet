# == Class: cassandra
#
# Installs and configures a Cassandra server
#
# (Much of this module was adapted from:
# https://github.com/msimonin/puppet-cassandra)
#
# Note:  This class requires the Puppet stdlib module, particularly the pick() function.
#
# === Usage
# class { '::cassandra':
#     cluster_name => 'my_cluster',
#     seeds        => ['10.11.12.13', '10.11.13.14'],
#     dc           => 'my_datacenter1',
#     rack         => 'my_rack1',
# #   ...
# }
#
# === Parameters
# [*cluster_name*]
#   The logical name of this Cassandra cluster.
#   Default: Test Cluster
#
# [*tls_cluster_name*]
#   If specified, use private keys (client and server) from private.git
#   belonging to this cluster. Also install the cluster's CA as trusted.
#   Default: undef
#
# [*instances*]
#   An hash from instance name to several instance-specific parameters,
#   including:
#     * jmx_port        must be unique per-host
#     * listen_address  address to use for cassandra clients
#     * rpc_address     address to use for cassandra cluster traffic
#   See also cassandra::instance
#
#   Unless default behaviour (as in Cassandra's Debian package) is wanted, each
#   instance will have its configuration deployed at /etc/cassandra-<TITLE>
#   with data at /srv/cassandra-<TITLE> and a corresponding nodetool
#   binary named nodetool-<TITLE> to be used to access instances individually.
#   Similarly each instance service will be available under
#   "cassandra-<TITLE>".
#
# [*default_instance_params*]
#   A hash of default instance parameters, to reduce duplication when multiple
#   instances share the same configuration. A hash is used instead of
#   parameters on the cassandra class to better identify parameters that only
#   apply to instances and not to the cassandra class. Some shared parameters
#   are still present on the cassandra class, either because they are used
#   directly by the cassandra class, or because they are referenced from other
#   classes / modules.
#   Default: {}
#
# [*seeds*]
#   Array of seed IPs for this Cassandra cluster.
#   Default: [$::ipaddress]
#
# [*listen_address*]
#   Cassandra listen IP address.  Default $::ipaddress
#
# [*additional_jvm_opts*]
#   Additional options to pass to the JVM.
#   Default: []
#
# [*extra_classpath*]
#   Additional files and/or directories to append to the JVM classpath.
#   Default: []
#
# [*target_version*]
#   The Cassandra version to configure for.  Valid choices are '2.1', '2.2', and '3.x'.
#   Default: 2.1
#
# [*memory_allocator*]
#   The off-heap memory allocator.
#   Default: JEMallocAllocator
#
# [*application_username*]
#   Non-superuser user; Username for application access.
#   Default: undef
#
#   If set, a CQL file will be created in /etc/cassandra/adduser.cql to
#   provision the respective user and grants with cqlsh:
#
#   cqlsh --cqlshrc=/etc/cassandra/cqlshrc -f /etc/cassandra/adduser.cql $HOSTNAME
#
# [*application_password*]
#   Password for application user.
#   Default: undef
#
# [*native_transport_port*]
#   Native transport listen port.  Default: 9042
#
# [*dc*]
#   Logical name datacenter name.  This will only be used
#   if $endpoint_snitch is GossipingPropertyFileSnitch.
#   Default:  dc1
#
# [*rack*]
#   Logical rack name.  This will only be used
#   if $endpoint_snitch is GossipingPropertyFileSnitch.
#   Default rack1
#
# [*start_rpc*]
#   Whether to start the thrift rpc server.  Default: true
#
class cassandra (
    $cluster_name            = 'Test Cluster',
    $tls_cluster_name        = undef,
    $instances               = undef,
    $default_instance_params = {},
    $seeds                   = [$::ipaddress],
    $listen_address          = $::ipaddress,
    $additional_jvm_opts     = [],
    $extra_classpath         = [],
    $target_version          = '2.1',
    $memory_allocator        = 'JEMallocAllocator',
    $application_username    = undef,
    $application_password    = undef,
    $native_transport_port   = 9042,
    $dc                      = 'datacenter1',
    $rack                    = 'rack1',
    $logstash_host           = 'logstash1003.eqiad.wmnet',
    $logstash_port           = 11514,
    $start_rpc               = true,
) {
    validate_string($cluster_name)

    validate_absolute_path($commitlog_directory)
    validate_absolute_path($hints_directory)
    validate_absolute_path($saved_caches_directory)

    validate_string($endpoint_snitch)

    validate_re($rpc_server_type, '^(hsha|sync|async)$')
    # lint:ignore:only_variable_string
    validate_re("${concurrent_reads}", '^[0-9]+$')
    validate_re("${concurrent_writes}", '^[0-9]+$')
    validate_re("${num_tokens}", '^[0-9]+$')
    # lint:endignore
    validate_re($internode_compression, '^(all|dc|none)$')
    validate_re($disk_failure_policy, '^(stop|best_effort|ignore)$')

    validate_array($additional_jvm_opts)
    validate_array($extra_classpath)


    if (!($target_version in ['2.1', '2.2', '3.x'])) {
        fail("${target_version} is not a valid Cassandra target version!")
    }

    package { 'openjdk-8-jdk':
        ensure  => 'installed',
    }

    # Cassandra and JVM utils
    package { 'cassandra-tools-wmf':
        ensure  => 'installed',
        require => Package['cassandra'],
    }
    package { 'jvm-tools':
        ensure  => 'installed',
        require => Package['openjdk-8-jdk'],
    }

    # We pin the version to a specific one
    $package_version = $target_version ? {
        '2.1' => hiera('cassandra::version', '2.1.13'),
        '2.2' => hiera('cassandra::version', '2.2.6-wmf1'),
        '3.x' => hiera('cassandra::version', '3.11.0')
    }
    package { 'cassandra':
        ensure  => $package_version,
        require => Package['openjdk-8-jdk'],
    }

    # Make sure libjemalloc is installed if
    # we are going to use the JEMallocAllocator.
    if $memory_allocator == 'JEMallocAllocator' {
        package { 'libjemalloc1':
            ensure => 'installed',
        }
    }

    # Create non-default cassandra instances if requested.
    # Default is to keep Debian package behaviour,
    # in other words create a "default" instance.
    $default_for_multi_instances = {
        cluster_name          => $cluster_name,
        tls_cluster_name      => $tls_cluster_name,
        seeds                 => $seeds,
        additional_jvm_opts   => $additional_jvm_opts,
        extra_classpath       => $extra_classpath,
        memory_allocator      => $memory_allocator,
        listen_address        => $listen_address,
        application_username  => $application_username,
        application_password  => $application_password,
        native_transport_port => $native_transport_port,
        target_version        => $target_version,
        dc                    => $dc,
        rack                  => $rack,
        logstash_host         => $logstash_host,
        logstash_port         => $logstash_port,
        start_rpc             => $start_rpc,
    }

    if empty($instances) {
        $defaults_for_single_instance = {
            config_directory       => '/etc/cassandra',
            service_name           => 'cassandra',
            tls_hostname           => $::hostname,
            pid_file               => '/var/run/cassandra/cassandra.pid',
            instance_id            => $::hostname,
            jmx_port               => 7199,
            data_directory_base    => '/var/lib/cassandra',
            commitlog_directory    => '/var/lib/cassandra/commitlog',
            hints_directory        => '/var/lib/cassandra/data/hints',
            heapdump_directory     => '/var/lib/cassandra/',
            saved_caches_directory => '/var/lib/cassandra/saved_caches',
        }
        $actual_defaults = merge(
            $default_for_multi_instances,
            $defaults_for_single_instance,
            $default_instance_params
        )
        $instances_to_create = {
            'default' => {}
        }
    } else {
        $instances_to_create = $instances
        $actual_defaults = merge(
            $default_for_multi_instances,
            $default_instance_params
        )
        # if running multi-instances, make sure the default instance is stopped
        service { 'cassandra':
            ensure => stopped,
        }
    } else {
        $default_instances = {
            'default' => {
                'jmx_port'               => $jmx_port,
                'listen_address'         => $listen_address,
                'rpc_address'            => $rpc_address,
                'data_directory_base'    => $data_directory_base,
                'data_file_directories'  => $data_file_directories,
                'commitlog_directory'    => $commitlog_directory,
                'hints_directory'        => $hints_directory,
                'heapdump_directory'     => $heapdump_directory,
                'saved_caches_directory' => $saved_caches_directory,
        }}
        cassandra::instance{ 'default':
            instances => $default_instances,
        }
    }
    create_resources(cassandra::instance, $instances_to_create, $actual_defaults)

    $jbod_devices = hiera('cassandra::jbod_devices', [])
    cassandra::jbod_device { $jbod_devices: }

    # nodetool wrapper to handle multiple instances, for each instance there
    # will be symlinks from /usr/local/bin/nodetool-<INSTANCE_NAME> to
    # nodetool-instance
    file { '/usr/local/bin/nodetool-instance':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/nodetool-instance",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0555',
        require => Package['cassandra'],
    }

    file { '/etc/cassandra.in.sh':
        ensure  => present,
        content => template("${module_name}/cassandra.in.sh.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    # no-op sysv init script
    file { '/etc/init.d/cassandra':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/cassandra-init.d",
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['cassandra'],
    }

    file { '/etc/tmpfiles.d/cassandra.conf':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/cassandra-tmpfiles.conf",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    file { '/etc/cassandra-instances.d':
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0755',
        require => Package['cassandra'],
    }

    scap::target { 'prometheus/jmx_exporter':
        deploy_user => 'deploy-service',
        manage_user => true,
    }
}
