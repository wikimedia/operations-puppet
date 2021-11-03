class puppetmaster::r10k (
    Stdlib::Unixpath                         $environments_path = '/etc/puppet/code/environments',
    Stdlib::Unixpath                         $config_file       = '/etc/puppet/r10k.conf',
    Stdlib::Unixpath                         $cache_dir         = '/var/cache/r10k',
    Boolean                                  $exclude_spec      = true,
    Hash[String, Puppetmaster::R10k::Source] $sources           = {},
) {
    include puppetmaster
    ensure_packages('r10k')
    $default_sources = {
        'production'  => {
            'remote'  => "${puppetmaster::gitdir}/operations/puppet",
            'basedir' => $environments_path,
        },
        'dev' => {
            'remote'  => 'https://gerrit.wikimedia.org/r/operations/puppet',
            'basedir' => $environments_path,
            'prefix'  => true,
        },
    }
    $_sources = $sources.empty ? {
        true    => $default_sources,
        default => Hash($sources.map |$items| { [$items[0], {'basedir' => $environments_path} + $items[1]]}),
    }
    $config = {
        'cachedir' => $cache_dir,
        'sources'  => $_sources,
        'deploy'   => {'exclude_spec' => $exclude_spec},
    }
    file { [$environments_path, $cache_dir]:
        ensure => directory,
    }
    file { $config_file:
        ensure  => file,
        content => $config.to_yaml,
        notify  => Exec['deploy r10k'],
    }
    exec { 'deploy r10k':
        command     => "/usr/bin/r10k -c ${config_file} deploy environment",
        refreshonly => true,
        require     => [
            Package['r10k'],
            File[$config_file],
        ],
    }
    # TODD: create a job/update git-sync-upstream to sync r10k
}
