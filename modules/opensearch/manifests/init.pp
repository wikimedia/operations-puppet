# SPDX-License-Identifier: Apache-2.0
# = Class: opensearch
#
# This class installs/configures/manages the opensearch service.
#
# == Parameters:
# - $default_instance_params: Parameter overrides for ::opensearch::instance
# - $version: Version of opensearch to configure. Either 1 or 2. Default: 1.
# - $logstash_host: Host to send logs to
# - $logstash_logback_port: Tcp port on localhost to send structured logs to.
# - $logstash_transport: Transport mechanism for logs.
#
# == Sample usage:
#
#   class { 'opensearch':
#       default_instance_params => {
#           cluster_name => 'labs-search',
#       }
#   }
#
class opensearch (
    Optional[Hash[String, Opensearch::InstanceParams]] $instances               = undef,
    Opensearch::SemVer                                 $version                 = '2.7.0',
    Opensearch::InstanceParams                         $default_instance_params = {},
    Stdlib::Absolutepath                               $base_data_dir           = '/srv/opensearch',
    Optional[String]                                   $logstash_host           = undef,
    Optional[Stdlib::Port]                             $logstash_logback_port   = 11514,
    Optional[String]                                   $rack                    = undef,
    Optional[String]                                   $row                     = undef,
    Optional[String]                                   $java_home               = undef,
    Boolean                                            $enable_curator          = false,
    Optional[String]                                   $native_lib_path         = undef,
    Optional[Array]                                    $plugins_mandatory       = [],
) {
    # Check that the version of the package corresponds to a released version
    unless $version { fail('Please specify an opensearch version to install') }

    # move up so we can use this var in the workaround below, it used to be down further
    # next to "systemd::unit"
    $major_version = split($version, '[.]')[0]

    # Workaround: OpenSearch 2.19+ deb postinst runs a security demo that
    # requires OPENSEARCH_INITIAL_ADMIN_PASSWORD. Without it the package is
    # left half-installed. WMF does not use the security plugin.
    # Upstream fix: https://github.com/opensearch-project/opensearch-build/pull/5554
    # Remove this exec once upstream ships a DISABLE_INSTALL_DEMO_CONFIG flag.
    # Only 2.19+; Observability uses version 2.7 which we'll exclude here.
    if versioncmp($version, '2.19.0') >= 0 {
        exec { 'install-opensearch':
            command     => "/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install opensearch=${version}",
            environment => [
                'OPENSEARCH_INITIAL_ADMIN_PASSWORD=OpensearchTemp1!',
                'DEBIAN_FRONTEND=noninteractive',
            ],
            unless      => "/usr/bin/dpkg-query -W -f='\${Status} \${Version}\\n' opensearch 2>/dev/null | /bin/grep -Fxq 'install ok installed ${version}'",
            before      => Package['opensearch'],
            timeout     => 300,
            logoutput   => false,
        }
        # The OpenSearch packages come with a lot of plugins
        # we don't want or need. This override helps us
        # expose only the plugins we explicitly set via
        # the $plugins_mandatory var
        systemd::override { "opensearch_${major_version}@":
            unit    => "opensearch_${major_version}@",
            content => epp('opensearch/initscripts/opensearch_2@.plugins-override.conf.epp', {
                plugins_mandatory => $plugins_mandatory,
            })
        }
    }

    if empty($instances) {
        $cluster_name = $default_instance_params['cluster_name']
        $defaults_for_single_instance = {
            http_port          => 9200,
            transport_tcp_port => 9300,
        }
        $configured_instances = {
            $cluster_name => merge(
                $defaults_for_single_instance,
                $default_instance_params
            )
        }
    } else {
        $configured_instances = $instances.reduce({}) |$agg, $kv_pair| {
            $instance_params = merge($default_instance_params, $kv_pair[1])
            $cluster_name = $instance_params['cluster_name']

            $agg + [$cluster_name, $instance_params]
        }
    }

    class { 'opensearch::packages':
        version               => $version,
        # Hack to be resolved in followup patch
        send_logs_to_logstash => $configured_instances.reduce(false) |Boolean $agg, $kv_pair| {
            $agg or pick_default($kv_pair[1]['send_logs_to_logstash'], true)
        }
    }

    if ($enable_curator) {
        class { 'opensearch::curator': }
    }

    # Overwrite default env file provided by opensearch
    # so that it does not conflict without our var set by systemd unit
    file { '/etc/default/opensearch':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => file('opensearch/opensearch.env'),
        require => Package['opensearch']
    }

    # main opensearch dir, purge it to ensure any undefined config file is removed
    file { '/etc/opensearch':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
    }

    # These files are created when the server is using the default cluster_name
    # and are never written to when the server is using the correct cluster name
    # thus leaving old files with no useful information named in such a way that
    # someone might think they contain useful logs.
    file { '/var/log/opensearch/opensearch.log':
        ensure => absent,
    }
    file { '/var/log/opensearch/opensearch_index_indexing_slowlog.log':
        ensure => absent,
    }
    file { '/var/log/opensearch/opensearch_index_search_slowlog.log':
        ensure => absent,
    }

    file { [ $base_data_dir, '/var/log/opensearch' ]:
        ensure  => directory,
        owner   => 'opensearch',
        group   => 'opensearch',
        mode    => '0755',
        require => Package['opensearch'],
    }

    logrotate::rule { 'opensearch':
        ensure        => present,
        file_glob     => '/var/log/opensearch/*.log',
        frequency     => 'daily',
        copy_truncate => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 7,
        compress      => true,
    }

    # since we are using our own systemd unit, ensure that the service
    # installed by the debian package is disabled
    service { 'opensearch':
        ensure  => stopped,
        enable  => false,
        require => Package['opensearch'],
    }

    systemd::unit { "opensearch_${major_version}@.service":
        ensure  => present,
        content => systemd_template("opensearch_${major_version}@"),
    }

    $configured_instances.each |$instance_title, $instance_params| {
        opensearch::instance { $instance_title:
            version               => $version,
            base_data_dir         => $base_data_dir,
            logstash_host         => $logstash_host,
            logstash_logback_port => $logstash_logback_port,
            rack                  => $rack,
            row                   => $row,
            require               => Package['opensearch'],
            configure_curator     => $enable_curator,
            *                     => $instance_params,
        }
    }

    $services_names = $configured_instances.map |$instance_title, $instance_params| {
        "opensearch_${major_version}@${instance_params['cluster_name']}"
    }

    file { '/etc/opensearch/instances':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => join($services_names, "\n"),
    }

}
