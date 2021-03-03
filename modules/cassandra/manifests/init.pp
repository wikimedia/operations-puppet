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
# [*super_username*]
#   Cassandra superuser username.
#   Username and password for superuser will be written to
#   /etc/cassandra/cqlshrc for easy/unattended usage by cqlsh.
#   Default: cassandra
#
# [*super_password*]
#   Cassandra superuser password.
#   Default: cassandra
#
class cassandra (
    String                           $cluster_name            = 'Test Cluster',
    Optional[String]                 $tls_cluster_name        = undef,
    Hash                             $instances               = {},
    Hash                             $default_instance_params = {},
    Array[Stdlib::Host]              $seeds                   = [$::ipaddress],
    Stdlib::IP::Address              $listen_address          = $::ipaddress,
    Array[String]                    $additional_jvm_opts     = [],
    Array[String]                    $extra_classpath         = [],
    Enum['2.2', '3.x', 'dev']        $target_version          = '2.2',
    String                           $memory_allocator        = 'JEMallocAllocator',
    Optional[String]                 $application_username    = undef,
    Optional[String]                 $application_password    = undef,
    Stdlib::Port                     $native_transport_port   = 9042,
    String                           $dc                      = 'datacenter1',
    String                           $rack                    = 'rack1',
    Stdlib::Host                     $logstash_host           = 'logstash.svc.eqiad.wmnet',
    Stdlib::Port                     $logstash_port           = 11514,
    Boolean                          $start_rpc               = true,
    Array[String]                    $jbod_devices            = [],
    String                           $super_username          = 'cassandra',
    String                           $super_password          = 'cassandra',
    Optional[String]                 $version                 = undef
) {

    # Cassandra fully supports opendjdk-11 only from 4.0,
    # and on Buster openjdk-8 is not available.
    # https://issues.apache.org/jira/browse/CASSANDRA-9608
    if debian::codename::eq('buster') {
        apt::package_from_component { 'openjdk-8':
            component => 'component/jdk8',
            packages  => ['openjdk-8-jdk'],
        }

        alternatives::select { 'java':
            path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
            require => Package['openjdk-8-jdk']
        }
    }

    if debian::codename::le('stretch') {
        package { 'openjdk-8-jdk':
            ensure  => 'installed',
        }
    }

    # Tools packages
    package { 'cassandra-tools-wmf':
        ensure  => 'installed',
        require => Package['cassandra'],
    }
    package { 'jvm-tools':
        ensure  => 'installed',
        require => Package['openjdk-8-jdk'],
    }

    # We pin the version to a specific one
    # The 2.2.6-wmf5 package has been tested on Debian Stretch
    # and it works nicely
    $package_version = $target_version ? {
        '2.2' => pick($version, '2.2.6-wmf5'),
        '3.x' => pick($version, '3.11.4'),
        'dev' => pick($version, '3.11.4')
    }

    # Cassandra 3.x is installed using the newer component convention, (and
    # from dists/stretch-wikimedia).
    if ($target_version in ['3.x', 'dev']) {
        apt::repository { 'wikimedia-cassandra311':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'stretch-wikimedia',
            components => 'component/cassandra311',
            before     => Package['cassandra'],
        }
    }
    # Cassandra 2.2 is installed using the newer component convention
    elsif ($target_version == '2.2') {
        apt::repository { 'wikimedia-cassandra22':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/cassandra22',
            before     => Package['cassandra'],
        }
    }

    package { 'cassandra':
        ensure  => $package_version,
        require => [ Package['openjdk-8-jdk'], Exec['apt-get update'] ],
    }

    package { 'cassandra-tools':
      ensure  => $package_version,
      require => Package['cassandra'],
    }

    # Make sure libjemalloc is installed if
    # we are going to use the JEMallocAllocator.
    if $memory_allocator == 'JEMallocAllocator' {
        $libjemalloc = debian::codename::le('stretch') ? {
            true    => 'libjemalloc1',
            default => 'libjemalloc2',
        }
        package { $libjemalloc:
            ensure => 'installed',
        }
    }

    # Create non-default cassandra instances if requested.
    # Default is to keep Debian package behaviour,
    # in other words create a "default" instance.
    $default_common = {
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
        super_username        => $super_username,
        super_password        => $super_password,
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
            $default_common,
            $defaults_for_single_instance,
            $default_instance_params
        )
        $instances_to_create = {
            'default' => {}
        }
    } else {
        $instances_to_create = $instances
        $actual_defaults = merge(
            $default_common,
            $default_instance_params
        )
        # if running multi-instances, make sure the default instance is stopped
        service { 'cassandra':
            ensure => stopped,
        }
    }
    $instances_to_create.each |$instance, $params| {
        cassandra::instance {$instance:
            * => $actual_defaults + $params,
        }
    }
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
}
