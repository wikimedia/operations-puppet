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
# @param puppetdb_submit_only_urls if present puppetdb will be configured using these urls for writes only
# @param reports list of reports to configure
# @param enc_path path to an ENC script
# @param listen_host host to bind webserver socket
# @param autosign if true autosign agent all certs, if a path then execute that script to validate
# @param enable_jmx add the jmx java agent parameter
# @param jmx_port the port for jmx to bind to
# @param ssldir_on_srv used on cloud-vps; it allows storing certs on a detachable volume
# @param separate_ssldir used when the puppetserver is managed by a different puppet server #TODO remove this setting in favor of ssldir_on_srv
# @param auto_restart if true changes to config files will cause the puppetserver to either restart or
#   reload the puppetserver service
# @param extra_mounts hash of mount point name to path, mount point name will used in puppet:///<MOUNT POINT>
# @param environment_timeout, number of seconds to cache code from an environment, or unlimited to never evict the cache
# @param ca_allow_san whether to allow agents to request SANs
# @param ca_name override the default Puppet CA name
# @param strict_mode enable "strict mode", same as defaults in Puppet 8, https://github.com/puppetlabs/puppet/wiki/Puppet-8-Compatibility#strict-mode
class puppetserver (
    Wmflib::Ensure                           $ensure                    = 'present',
    Stdlib::Fqdn                             $server_id                 = $facts['networking']['fqdn'],
    Stdlib::Fqdn                             $ca_server                 = $server_id,
    Integer[1]                               $max_active_instances      = $facts['processors']['count'],
    Stdlib::Unixpath                         $config_dir                = '/etc/puppet',
    Stdlib::Unixpath                         $code_dir                  = "${config_dir}/code",
    Stdlib::Unixpath                         $hiera_data_dir            = "${config_dir}/hieradata",
    Stdlib::Datasize                         $java_start_mem            = '1g',
    Stdlib::Datasize                         $java_max_mem              = '1g',
    Array[Puppetserver::Hierarchy]           $hierarchy                 = [],
    Array[Stdlib::HTTPUrl]                   $puppetdb_urls             = [],
    Array[Stdlib::HTTPUrl]                   $puppetdb_submit_only_urls = [],
    Array[Puppetserver::Report,1]            $reports                   = ['store'],
    Optional[Stdlib::Unixpath]               $enc_path                  = undef,
    Stdlib::Host                             $listen_host               = $facts['networking']['ip'],
    Variant[Boolean, Stdlib::Unixpath]       $autosign                  = false,
    Boolean                                  $ssldir_on_srv             = false,
    Boolean                                  $separate_ssldir           = true,
    Boolean                                  $enable_jmx                = false,
    Boolean                                  $auto_restart              = true,
    Stdlib::Port                             $jmx_port                  = 8141,
    Hash[String, Stdlib::Unixpath]           $extra_mounts              = {},
    Variant[Enum['unlimited'], Integer]      $environment_timeout       = 0,
    Boolean                                  $ca_allow_san              = false,
    Optional[String[1]]                      $ca_name                   = undef,
    Boolean                                  $strict_mode               = true,
) {
    systemd::mask { 'puppetserver.service':
        unless => '/usr/bin/dpkg -s puppetserver | /bin/grep -q "^Status: install ok installed$"',
    }
    ensure_packages(['puppetserver'])
    systemd::unmask { 'puppetserver.service':
        refreshonly => true,
    }
    # Ensure puppetserver is not started on the first install
    # As we first need to configure the CA
    Systemd::Mask['puppetserver.service'] -> Package['puppetserver'] ~> Systemd::Unmask['puppetserver.service']

    $owner = 'puppet'
    $group = 'puppet'
    $ruby_load_path = '/usr/lib/puppetserver/ruby/vendor_ruby'
    $puppetserver_config_dir = "${config_dir}/puppetserver"
    # This is defined in /puppetserver.conf
    # This is used in systemd
    $config_d_dir = "${puppetserver_config_dir}/conf.d"
    $ca_dir = "${puppetserver_config_dir}/ca"
    $bootstap_config_dir = "${puppetserver_config_dir}/services.d"
    if $ssldir_on_srv {
        $ssl_dir = '/srv/puppet/server/ssl'
    } else {
        $ssl_dir = $separate_ssldir.bool2str('/var/lib/puppet/server/ssl', '/var/lib/puppet/ssl')
    }
    $environments_dir = "${code_dir}/environments"

    $service_reload_notify = $auto_restart ? {
        true  => Exec['reload puppetserver'],
        false => Exec['restart puppetserver required'],
    }
    $service_restart_notify = $auto_restart ? {
        true  => Service['puppetserver'],
        false => Exec['restart puppetserver required'],
    }

    # Frustratingly, puppet requires us to specify 'none' when
    #  we don't want reports (e.g. on cloud-vps.). When appending
    #  to that list we need to remove the 'none' to avoid a weird
    #  situation of having ['none', 'something'] in the list of
    #  report types.
    $_reports = $puppetdb_urls.empty ? {
        true  => $reports,
        false => $reports.delete('none') + 'puppetdb',
    }

    wmflib::dir::mkdir_p(
        [
            $code_dir,
            $environments_dir,
            $config_dir,
        ],
        {
            'mode'  => '0755',
        },
    )

    file { $config_d_dir:
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    # Shared by profile::puppet::agent, but needs to have the correct
    # permissions prior to starting Puppet
    ensure_resource(
        'file',
        '/var/lib/puppet',
        {
            'ensure' => 'directory',
            'owner'  => 'puppet',
            'group'  => 'puppet',
            'mode'   => '0751',
        },
    )

    if $ssldir_on_srv {
        ensure_resource(
            'file',
            '/srv/puppet/server',
            {
                'ensure' => 'directory',
                'owner'  => 'puppet',
                'group'  => 'puppet',
                'mode'   => '0751',
            },
        )
        ensure_resource(
            'file',
            '/etc/puppet/puppetserver/ca',
            {
                'ensure' => link,
                'target' => '/srv/puppet/server/ssl/ca'
            },
        )
    } elsif $separate_ssldir {
        ensure_resource(
            'file',
            '/var/lib/puppet/server',
            {
                'ensure' => 'directory',
                'owner'  => 'puppet',
                'group'  => 'puppet',
                'mode'   => '0751',
            },
        )
    }


    # The puppetserver process itself enforces mode 0771 on the ssl dir, so this
    # should not be changed or it will create a perma-diff
    file { $ssl_dir:
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0771',
    }

    wmflib::dir::mkdir_p(
        [
            $puppetserver_config_dir,
            $bootstap_config_dir,
        ],
        {
            'owner' => $owner,
            'group' => $group,
            'mode'  => '0755',
        },
    )

    $config = @("CONFIG")

    [server]
    ca_server = ${ca_server}
    reports = ${_reports.unique.join(',')}
    codedir = ${code_dir}
    environment_timeout = ${environment_timeout}
    | CONFIG
    concat::fragment { 'server':
        target  => '/etc/puppet/puppet.conf',
        order   => '20',
        content => $config,
        notify  => $service_reload_notify,
        require => Systemd::Unmask['puppetserver.service'],
    }
    if ! $puppetdb_urls.empty {
        concat::fragment { 'server-storeconfigs':
            target  => '/etc/puppet/puppet.conf',
            order   => '21',
            content => "storeconfigs = true\nstoreconfigs_backend = puppetdb\n",
            notify  => $service_reload_notify,
            require => Systemd::Unmask['puppetserver.service'],
        }
    }
    if $enc_path {
        concat::fragment { 'server-enc':
            target  => '/etc/puppet/puppet.conf',
            order   => '22',
            content => "node_terminus = exec\nexternal_nodes = ${enc_path}\n",
            notify  => $service_reload_notify,
            require => Systemd::Unmask['puppetserver.service'],
        }
    }
    if $autosign {
        concat::fragment { 'server-autosign':
            target  => '/etc/puppet/puppet.conf',
            order   => '23',
            content => "autosign = ${autosign}\n",
            notify  => $service_reload_notify,
            require => Systemd::Unmask['puppetserver.service'],
        }
    }
    if $separate_ssldir {
        concat::fragment { 'separate-ssldir':
            target  => '/etc/puppet/puppet.conf',
            order   => '24',
            content => "ssldir = ${ssl_dir}\n",
            notify  => $service_reload_notify,
            require => Systemd::Unmask['puppetserver.service'],
        }
    }
    if $ca_name {
        concat::fragment { 'ca-name':
            target  => '/etc/puppet/puppet.conf',
            order   => '25',
            content => "ca_name = ${ca_name}\n",
            notify  => $service_reload_notify,
            require => Systemd::Unmask['puppetserver.service'],
        }
    }
    if $strict_mode {
        $strict_mode_config = @("STRICT_MODE_CONFIG")
        # Puppet 8 strict mode defaults for Puppet 7, these
        # settings may be removed when we have upgraded to
        # Puppet 8
        strict_variables = true
        strict = error
        | STRICT_MODE_CONFIG
        concat::fragment { 'server-strict-mode':
            target  => '/etc/puppet/puppet.conf',
            order   => '26',
            content => $strict_mode_config,
            notify  => $service_reload_notify,
            require => Systemd::Unmask['puppetserver.service'],
        }
    }

    # TODO: puppetserver has support for graphite and jmx (with jolokia)
    # we will need to work out which is best
    $metrics_params = { 'server_id'                    => $server_id }
    $puppetserver_params = {
        'ruby_load_path'       => $ruby_load_path,
        'config_dir'           => $config_dir,
        'code_dir'             => $code_dir,
        'max_active_instances' => $max_active_instances,
    }
    $jmx_config = "${puppetserver_config_dir}/jmx_exporter.yaml"
    $environment_file_params = {
        'java_start_mem'      => $java_start_mem,
        'java_max_mem'        => $java_max_mem,
        'config_d_dir'        => $config_d_dir,
        'bootstap_config_dir' => $bootstap_config_dir,
        'enable_jmx'          => $enable_jmx,
        'jmx_port'            => $jmx_port,
        'jmx_config'          => $jmx_config,
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
    $auth_params = {
        'fqdn' => $facts['networking']['fqdn'],
    }
    $ca_params = {
        'allow_san' => $ca_allow_san,
    }
    # Ensure additional mounts exist
    unless $extra_mounts.empty {
        wmflib::dir::mkdir_p($extra_mounts.values(), {mode => '0555'})
    }
    $fileserver_content = $extra_mounts.reduce("# Managed by puppet\n") |$memo, $value| {
        $tmp = @("CONTENT")
        [${value[0]}]
            path ${value[1]}
        | CONTENT
        # Note If we add memo to the heredoc above we get the following error
        #  Syntax error at '['
        # Have not been able to recreate in a simple repro i.e. the following works
        # https://phabricator.wikimedia.org/P50573
        "${memo}${tmp}"
    }
    file {
        default:
            ensure  => stdlib::ensure($ensure, 'file'),
            require => Systemd::Unmask['puppetserver.service'],
            notify  => $service_reload_notify;
        "${config_d_dir}/metrics.conf":
            content => epp('puppetserver/metrics.conf.epp', $metrics_params);
        "${config_d_dir}/puppetserver.conf":
            content => epp('puppetserver/puppetserver.conf.epp', $puppetserver_params);
        # TODO: do we need to manage this?  possibly disable/change admin api end point
        "${config_d_dir}/web-routes.conf":
            content => epp('puppetserver/web-routes.conf.epp');
        "${config_d_dir}/webserver.conf":
            content => epp('puppetserver/webserver.conf.epp', $web_server_params);
        "${config_d_dir}/auth.conf":
            content => epp('puppetserver/auth.conf.epp', $auth_params);
        "${config_d_dir}/ca.conf":
            content => epp('puppetserver/ca.conf.epp', $ca_params);
        "${config_d_dir}/global.conf":
            source =>  'puppet:///modules/puppetserver/global.conf';
        '/etc/puppet/hiera.yaml':
            content => $hiera_config.to_yaml;
        '/etc/puppet/fileserver.conf':
            content => $fileserver_content;
        '/etc/default/puppetserver':
            content => epp('puppetserver/environment_file.epp', $environment_file_params),
            notify  => $service_restart_notify;
    }
    include puppetserver::puppetdb
    if $enable_jmx {
        ensure_packages(['prometheus-jmx-exporter'])
        file { $jmx_config:
            ensure  => file,
            content => epp('puppetserver/jmx_exporter.yaml.epp'),
        }
        $service_require = [File[$ssl_dir], Package['prometheus-jmx-exporter']]
        # This is quite specific to the WMF systems it might be better to move this to some profile
        prometheus::jmx_exporter_instance { 'puppetserver':
            hostname => $facts['networking']['hostname'],
            port     => $jmx_port,
        }
    } else {
        $service_require = File[$ssl_dir]
    }
    service { 'puppetserver':
        ensure  => stdlib::ensure($ensure, 'service'),
        enable  => true,
        require => $service_require,
    }
    exec { 'reload puppetserver':
        command     => '/usr/bin/systemctl reload puppetserver',
        refreshonly => true,
    }
    # Add a file indicating that a restart or reload is required this file exists for other tooling to consume
    exec { 'restart puppetserver required':
        path        => '/usr/bin',
        command     => 'printf "Restart required from %s\n" "$(date)" >> /run/puppetserver/restart_required',
        refreshonly => true,
    }

    file { '/usr/local/bin/puppetserver-deploy-code':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/puppetserver/puppetserver-deploy-code.sh',
        mode   => '0555',
    }
}
