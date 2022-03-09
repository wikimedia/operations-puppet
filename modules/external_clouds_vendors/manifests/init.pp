# @summery class to sintall automatic updataing of the public_clous.json netmapper file
# @param ensure ensurable
# @param user user to use for downloading file
# @param group to use for file permissions
# @param manage_user set to false if the user is managed elsewhere
# @param conftool set to true if you want to upload data to etcd.
# @param outfile location to write the results
# @param http_proxy http proxy server to use will be used for both http and https
class external_clouds_vendors (
    Wmflib::Ensure            $ensure      = 'present',
    String[1]                 $user        = 'external-clouds-fetcher',
    String[1]                 $group       = 'root',
    Boolean                   $manage_user = true,
    Boolean                   $conftool    = false,
    Stdlib::Unixpath          $outfile     = '/srv/external_clouds_vendors/public_clouds.json',
    Optional[Stdlib::HTTPUrl] $http_proxy  = undef,
) {
    ensure_packages(['python3-lxml', 'python3-netaddr', 'python3-requests', 'python3-wmflib'])
    if $manage_user {
        systemd::sysuser { $user:
            description => 'User used for downloading external cloud vendor networks',
        }
    }
    $environment = $http_proxy ? {
        undef   => {},
        default => Hash( ['http_proxy', 'https_proxy' ].map |$env| {[$env, $http_proxy, $env.upcase, $http_proxy]}.flatten)
    }
    if !defined($outfile.dirname) {
        file { $outfile.dirname():
            ensure  => stdlib::ensure($ensure, 'directory'),
            owner   => $user,
            group   => $group,
            require => Systemd::Sysuser[$user],
        }
    }
    file { '/usr/local/bin/fetch-external-clouds-vendors-nets':
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0554',
        owner   => $user,
        group   => $group,
        source  => 'puppet:///modules/external_clouds_vendors/fetch_external_clouds_vendors_nets.py',
        require => Systemd::Sysuser[$user],
    }
    file { $outfile:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0644',
        owner   => $user,
        group   => $group,
        # set replace false to ensure we only create content if no file already exists
        replace => false,
        content => '{}',
        require => Systemd::Sysuser[$user],
    }
    $opts = $conftool.bool2str('-c', '')
    $command = "/usr/local/bin/fetch-external-clouds-vendors-nets ${opts} -vc ${outfile}"
    systemd::timer::job { 'dump_cloud_ip_ranges':
        ensure            => $ensure,
        command           => $command,
        description       => 'Job to update list of cloud ip ranges',
        user              => $user,
        logging_enabled   => true,
        syslog_identifier => 'fetch-external-clouds-vendors-nets',
        environment       => $environment,
        interval          => {'start' => 'OnCalendar', 'interval' => 'daily'},
        require           => Systemd::Sysuser[$user],
    }
}

