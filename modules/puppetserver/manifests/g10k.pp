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
    ensure_packages('g10k')
    $_sources =  Hash($sources.map |$items| {
        [$items[0], { 'basedir' => "${puppetserver::environments_dir}_staging" } + $items[1]]
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
}
