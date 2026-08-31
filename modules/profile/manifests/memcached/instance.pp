# SPDX-License-Identifier: Apache-2.0
# == Class: profile::memcached::instance
#
# Installs and configures a memcached instance.
#
# === Parameters
#
# [*version*]
#   There are different package versions available due to a performance test,
#   most of them are deployed/installed manually. More info: T129963
#
# [*port*]
#   Memcached TCP listening port.
#
# [*size*]
#   Memcached max memory allocated size, in megabytes.
#
# [*extended_options*]
#   Extended options to enable various memcached features.
#   Default: []
#
# [*max_seq_reqs*]
#   Maximum number of sequential requests (over the same TCP conn)
#   that memcached will process before yielding to another connection
#   (to avoid starving clients). Sets the '-R' option in memcached.
#   Default: 200 (memcached's default is 20)
#
# [*growth_factor*]
#   Slab growth factor.
#   Default: 1.25
#
# [*memcached_user*]
#   User to run memcached as.
#   Default: undef
#
# [*performance_cpu_governor*]
#   Enable the CPU governor for performance.
#
# [*extstore_ensure*]
#   Ensure state of the extstore path.  This enables the extstore featur Default: absent
#   https://github.com/memcached/memcached/wiki/Extstore
#
# [*extstore_path*]
#   Path to the extstore path. Default: /mnt/memcached.
#
# [*extstore_size*]
#   Size of extstore. Default: 20
#
# [*min_slab_size*]
#   Size of the first/smallest slab. The other slabs will be created
#   using the growth_factor parameter.
#   Default: 48
#
# [*threads*]
#   Processing threads used by memcached. Sets the '-t' option in memcached.
#   Before 1.5.x, the extensive use of locks was limiting the scalability
#   up to a maximum of 8.
#   Default: undef (memcached's default is 4)
#
# [*enable_tls_localhost*]
#   By default the socket on localhost will not be wrapped in TLS
#   This is to make debugging easier and support the prometheus exporter.
#   Set this to true to also wrap localhost
#   Default: false
#
# [*ssl_cert*]
#   The public key used for SSL connections
#   Default: undef
#
# [*ssl_key*]
#   The public key used for SSL connections
#   Default: undef

# [*localcacert*]
#   Location of ca.pem
#   Default: undef
#
# [*use_pki_certs]
#   Boolean. Whether to use the CFSSL based PKI to generate certificates,
#   or to use the older Puppet CA based certificates. Defaults to false.
#
# [*notls_port]
#   By default, when we `enable_tls`, the host will listen
#   `port` for TLS connections. By defining a `notls_port`,
#   we have the ability to listen for unencrypted connections
#   to a different port.
#   Default: undef
#
# [*enable_monitoring*]
#   Whether to enable Icinga monitoring checks.
#
# [*firewall_srange*]
#   By default no firewall port is opened. This allows to grant access to an array
#   of hosts
#
# [*firewall_src_sets*]
#   By default no firewall port is opened. This allows to grant access to an array
#   of firewall sets (e.g. DOMAIN_NETWORKS)
class profile::memcached::instance (
    String                     $version                 = lookup('profile::memcached::version'),
    Stdlib::Port               $port                     = lookup('profile::memcached::port'),
    Integer                    $size                     = lookup('profile::memcached::size'),
    Array[String]              $extended_options         = lookup('profile::memcached::extended_options'),
    Integer                    $max_seq_reqs             = lookup('profile::memcached::max_seq_reqs'),
    Integer                    $min_slab_size            = lookup('profile::memcached::min_slab_size'),
    Float                      $growth_factor            = lookup('profile::memcached::growth_factor'),
    String                     $memcached_user           = lookup('profile::memcached::memcached_user'),
    Optional[Boolean]          $performance_cpu_governor = lookup('profile::memcached::performance_cpu_governor'),
    Optional[WMFlib::Ensure]   $extstore_ensure          = lookup('profile::memcached::extstore_ensure'),
    Optional[Integer]          $extstore_size            = lookup('profile::memcached::extstore_size'),
    Optional[Stdlib::Unixpath] $extstore_path            = lookup('profile::memcached::extstore_path'),
    Optional[Boolean]          $enable_tls               = lookup('profile::memcached::enable_tls'),
    Optional[Stdlib::Port]     $notls_port               = lookup('profile::memcached::notls_port'),
    Optional[Stdlib::Unixpath] $ssl_cert_override        = lookup('profile::memcached::ssl_cert'),
    Optional[Stdlib::Unixpath] $ssl_key_override         = lookup('profile::memcached::ssl_key'),
    Optional[Stdlib::Unixpath] $localcacert_override     = lookup('profile::memcached::localcacert'),
    Boolean                    $use_pki_certs            = lookup('profile::memcached::use_pki_certs', {'default_value' => false}),
    Optional[Integer]          $threads                  = lookup('profile::memcached::threads'),
    Boolean                    $enable_monitoring        = lookup('profile::memcached::enable_monitoring', {default_value => true}),
    Optional[Array[String[1]]] $firewall_src_sets        = lookup('profile::memcached::firewall_src_sets', { 'default_value' => undef }),
    Optional[Firewall::Range]  $firewall_srange          = lookup('profile::memcached::firewall_srange', { 'default_value' => undef }),
) {
    include ::profile::prometheus::memcached_exporter
    if $performance_cpu_governor {
        class { 'cpufrequtils': }
    }

    $extstore = $extstore_ensure ? {
        present => ["ext_path=${extstore_path}/datafile:${extstore_size}G"],
        default => [],
    }

    $base_extra_options = {
        '-o' => join($extended_options+$extstore, ','),
        '-D' => ':',
    }

    if $max_seq_reqs {
        $max_seq_reqs_opt = {'-R' => $max_seq_reqs}
    } else {
        $max_seq_reqs_opt = {}
    }

    if $threads {
        $threads_opt = {'-t' => $threads}
    } else {
        $threads_opt = {}
    }

    $extra_options = $base_extra_options + $max_seq_reqs_opt + $threads_opt
    # We are migrating to PKI (T353511), using a feature flag.
    if ! $use_pki_certs {
        $ssl_cert = $ssl_cert_override
        $ssl_key = $ssl_key_override
        $localcacert = $localcacert_override
    }
    else {
        $var_dir = '/var/lib/memcached'
        file { $var_dir:
            ensure  => directory,
            owner   => $memcached_user,
            group   => $memcached_user,
            require => Package['memcached'],
        }
        # Default expiry 672h -> 28days. Cert will be renewed earlier.
        $ssl_paths = profile::pki::get_cert('discovery2026', $facts['networking']['fqdn'], {
            owner  => $memcached_user,
            group  => $memcached_user,
            outdir => "${var_dir}/ssl",
            before => Systemd::Service['memcached'],
            notify => Exec['memcached-refresh-certs'],
        })

        $ssl_cert = $ssl_paths['cert']
        $ssl_key = $ssl_paths['key']
        $localcacert = profile::base::certificates::get_trusted_ca_path()

        prometheus::node_textfile { 'prometheus-check-certificate-expiry':
            ensure         => 'present',
            filesource     => 'puppet:///modules/prometheus/check_certificate_expiry.py',
            interval       => 'daily',
            run_cmd        => "/usr/local/bin/prometheus-check-certificate-expiry --cert-path ${ssl_cert} --outfile /var/lib/prometheus/node.d/cert_expiry.prom",
            extra_packages => ['python3-cryptography', 'python3-prometheus-client'],
        }
    }
    # memcached re-reads its certificates on reload so a renewal does
    # not require a restart, and uses the new certificate immediately for
    # new connections.
    exec { 'memcached-refresh-certs':
        command     => '/usr/bin/systemctl reload memcached.service',
        onlyif      => '/usr/bin/systemctl is-active --quiet memcached.service',
        refreshonly => true,
    }

    class { '::memcached':
        size              => $size,
        port              => $port,
        version           => $version,
        growth_factor     => $growth_factor,
        min_slab_size     => $min_slab_size,
        extra_options     => $extra_options,
        memcached_user    => $memcached_user,
        enable_tls        => $enable_tls,
        notls_port        => $notls_port,
        ssl_cert          => $ssl_cert,
        ssl_key           => $ssl_key,
        localcacert       => $localcacert,
        extstore_ensure   => $extstore_ensure,
        extstore_path     => $extstore_path,
        enable_monitoring => $enable_monitoring,
        # we need the memcached configuration to be rebuilt before we reload the certificates.
        before            => Exec['memcached-refresh-certs']
    }

    if $firewall_src_sets {
        firewall::service { 'memcached':
            proto    => 'tcp',
            port     => $port,
            src_sets => $firewall_src_sets,
        }
    }

    if $firewall_srange {
        firewall::service { 'memcached':
            proto  => 'tcp',
            port   => $port,
            srange => $firewall_srange,
        }
    }

    if $notls_port and $enable_tls {
        if $firewall_src_sets {
            firewall::service { 'memcached_notls':
                proto    => 'tcp',
                port     => $notls_port,
                src_sets => $firewall_src_sets,
            }
        }

        if $firewall_srange {
            firewall::service { 'memcached_notls':
                proto  => 'tcp',
                port   => $notls_port,
                srange => $firewall_srange,
            }
        }
    }
}
