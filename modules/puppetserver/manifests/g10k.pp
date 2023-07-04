# SPDX-License-Identifier: Apache-2.0
# @summary install and manage g10k
# @param ensure ensureable param
# @param config_file path to the config file
# @param cache_dir path to the cache directory
# @param sources list of sources to configure
class puppetserver::g10k (
    Wmflib::Ensure                           $ensure      = 'present',
    Stdlib::Unixpath                         $config_file = '/etc/puppet/g10k.conf',
    Stdlib::Unixpath                         $cache_dir   = '/var/cache/g10k',
    Hash[String, Puppetmaster::R10k::Source] $sources     = {},
) {
    # Currently puppetserver::g10k is only ever called from puppetserver
    assert_private()
    ensure_packages('g10k')
    $_sources =  Hash($sources.map |$items| {
        [$items[0], { 'basedir' => $puppetserver::environments_dir } + $items[1]]
    })
    $config = {
        'cachedir' => $cache_dir,
        'sources'  => $_sources,
    }
    file { $cache_dir:
        ensure => stdlib::ensure($ensure, 'directory'),
    }
    file { $config_file:
        ensure  => stdlib::ensure($ensure, file),
        content => $config.to_yaml,
    }
    if $ensure == 'present' {
        exec { 'deploy g10k':
            command     => "/usr/bin/g10k -config ${config_file}",
            refreshonly => true,
            notify      => Service['puppetserver'],
            require     => Package['g10k'],
            subscribe   => File[$config_file],
        }
    }
    # TODD: create a job/update git-sync-upstream to sync g10k
}
