class puppetmaster::r10k (
    Stdlib::Unixpath                         $environments_path = '/etc/puppet/code/environments',
    Stdlib::Unixpath                         $config_file       = '/etc/puppet/r10k.conf',
    Hash[String, Puppetmaster::R10k::Source] $sources           = {},
) {
    include puppetmaster
    ensure_packages('r10k')
    $default_sources = {
        'production'  => {
            'remote'  => "${puppetmaster::gitdir}/operations/puppet",
            'basedir' => '/etc/puppet/code/environments',
        },
        'dev' => {
            'remote'  => 'https://gerrit.wikimedia.org/r/operations/puppet',
            'basedir' => '/etc/puppet/code/environments',
            'prefix'  => true,
        },
    }
    $config = {
        'sources' => $default_sources + $sources,
    }
    file { $environments_path:
        ensure => directory,
    }
    file { $config_file:
        ensure  => file,
        content => $config.to_yaml,
    }
    exec { 'deploy r10k':
        command => "/usr/bin/r10k -c ${config_file} deploy environment",
        creates => "${environments_path}/production",
        require => [
            Package['r10k'],
            File[$config_file],
        ],
    }

}
