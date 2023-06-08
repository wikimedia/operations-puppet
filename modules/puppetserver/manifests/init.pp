# SPDX-License-Identifier: Apache-2.0
# @param ensure ensurable parameter
# @param server_id the server id to use for the host
# @param ca_server the ca server
# @param max_active_instances number of instances to run
# @param java_start_mem the value to use for the java args -Xms
# @param java_max_mem the value to use for the java args -Xmx
# @param config_dir the directory where config is stored
# @param code_dir the directory where code is stored
# @param hiera_data_dir the default location for hiera data
# @param hierarchy a hash of hierarchy to add to the hiera file
# @param puppetdb_urls if present puppetdb will be configured using these urls
# @param reports list of reports to configure
# @param enc_path path to an ENC script
# @param listen_host host to bind webserver socket
# @param autosign if true autosign agent certs
# @param g10k_sources a list of g10k sources to configure
class puppetserver (
    Wmflib::Ensure                           $ensure               = 'present',
    Stdlib::Fqdn                             $server_id            = $facts['networking']['fqdn'],
    Stdlib::Fqdn                             $ca_server            = $server_id,
    Integer[1]                               $max_active_instances = $facts['processors']['count'],
    Stdlib::Unixpath                         $config_dir           = '/etc/puppet',
    Stdlib::Unixpath                         $code_dir             = "${config_dir}/code",
    Stdlib::Unixpath                         $hiera_data_dir       = "${config_dir}/hieradata",
    Stdlib::Datasize                         $java_start_mem       = '1g',
    Stdlib::Datasize                         $java_max_mem         = '1g',
    Array[Puppetserver::Hierarchy]           $hierarchy            = [],
    Array[Stdlib::HTTPUrl]                   $puppetdb_urls        = [],
    Array[Puppetserver::Report,1]            $reports              = ['store'],
    Optional[Stdlib::Unixpath]               $enc_path             = undef,
    Stdlib::Host                             $listen_host          = $facts['networking']['ip'],
    Boolean                                  $autosign             = false,
    Hash[String, Puppetmaster::R10k::Source] $g10k_sources         = {},
) {
    ensure_packages(['puppetserver'])
    $ruby_load_path = '/usr/lib/puppetserver/ruby/vendor_ruby'
    # This is defined in /puppetserver.conf
    # This is used in systemd
    $config_d_dir = "${config_dir}/puppetserver/conf.d"
    $bootstap_config_dir = "${config_dir}/puppetserver/services.d"
    $ssl_dir = '/var/lib/puppet/server/ssl'
    $environments_dir = "${code_dir}/environments"

    $_reports = $puppetdb_urls.empty ? {
        false   => $reports + 'puppetdb',
        default => $reports,
    }

    wmflib::dir::mkdir_p([$environments_dir, $config_dir])
    wmflib::dir::mkdir_p(
        $ssl_dir,
        {
            'owner' => 'puppet',
            'group' => 'puppet'
        },
    )

    $config = @("CONFIG")

    [server]
    ssldir = ${ssl_dir}
    ca_server = ${ca_server}
    reports = ${_reports.unique.join(',')}
    codedir = ${code_dir}
    | CONFIG
    concat::fragment { 'server':
        target  => '/etc/puppet/puppet.conf',
        order   => '20',
        content => $config,
        notify  => Service['puppetserver'],
    }
    if ! $puppetdb_urls.empty {
        concat::fragment { 'server-storeconfigs':
            target  => '/etc/puppet/puppet.conf',
            order   => '21',
            content => "storeconfigs = true\nstoreconfigs_backend = puppetdb\n",
            notify  => Service['puppetserver'],
        }
    }
    if $enc_path {
        concat::fragment { 'server-enc':
            target  => '/etc/puppet/puppet.conf',
            order   => '22',
            content => "node_terminus = exec\nexternal_nodes = ${enc_path}\n",
            notify  => Service['puppetserver'],
        }
    }
    if $autosign {
        concat::fragment { 'server-autosign':
            target  => '/etc/puppet/puppet.conf',
            order   => '23',
            content => "autosign = ${autosign}\n",
            notify  => Service['puppetserver'],
        }
    }

    # TODO: puppetserver has support for graphite and jmx (with jolokia)
    # we will need to work out which is best
    $metrics_params = { 'server_id' => $server_id }
    $puppetserver_params = {
        'ruby_load_path'       => $ruby_load_path,
        'config_dir'           => $config_dir,
        'code_dir'             => $code_dir,
        'max_active_instances' => $max_active_instances,
    }
    $environment_file_params = {
        'java_start_mem'      => $java_start_mem,
        'java_max_mem'        => $java_max_mem,
        'config_d_dir'        => $config_d_dir,
        'bootstap_config_dir' => $bootstap_config_dir,
    }
    $hiera_config = {
        'hierarchy' => $hierarchy,
        'version'   => 5,
        'defaults'  => {
            'datadir'   => $hiera_data_dir,
            'data_hash' => 'yaml_data',
        },
    }
    $web_server_params = {
        'listen_host' => $listen_host,
    }
    file {
        default:
            ensure  => stdlib::ensure($ensure, 'file'),
            require => Package['puppetserver'],
            notify  => Service['puppetserver'];
        "${config_d_dir}/metrics.conf":
            content => epp('puppetserver/metrics.conf.epp', $metrics_params);
        "${config_d_dir}/puppetserver.conf":
            content => epp('puppetserver/puppetserver.conf.epp', $puppetserver_params);
        # TODO: do we need to manage this?  possibly disable/change admin api end point
        "${config_d_dir}/web-routes.conf":
            content => epp('puppetserver/web-routes.conf.epp');
        "${config_d_dir}/webserver.conf":
            content => epp('puppetserver/webserver.conf.epp', $web_server_params);
        '/etc/puppet/hiera.yaml':
            content => $hiera_config.to_yaml;
        '/etc/default/puppetserver':
            content => epp('puppetserver/environment_file.epp', $environment_file_params);
    }
    include puppetserver::puppetdb
    $g10k_ensure = $g10k_sources.empty.bool2str('absent', $ensure)
    class { 'puppetserver::g10k':
        ensure  => $g10k_ensure,
        sources => $g10k_sources,
    }
    service { 'puppetserver':
        ensure  => stdlib::ensure($ensure, 'service'),
        enable  => true,
        require => File[$ssl_dir],
    }
}
