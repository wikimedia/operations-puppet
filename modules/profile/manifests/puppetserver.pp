# SPDX-License-Identifier: Apache-2.0
# @param hiera_data_dir the default location for hiera data
# @param hierarchy a hash of hierarchy to add to the hiera file
# @param code_dir the location where puppet looks for code
# @param reports list of reports to configure
# @param puppetdb_urls if present puppetdb will be configured using these urls
# @param enc the path to the enc to use
class profile::puppetserver (
    Stdlib::Unixpath               $code_dir       = lookup('profile::puppetserver::code_dir'),
    Stdlib::Unixpath               $hiera_data_dir = lookup('profile::puppetserver::hiera_data_dir'),
    Array[Puppetserver::Hierarchy] $hierarchy      = lookup('profile::puppetserver::hierarchy'),
    Array[Puppetserver::Report,1]  $reports        = lookup('profile::puppetserver::reports'),
    Array[Stdlib::HTTPUrl]         $puppetdb_urls  = lookup('profile::puppetserver::puppetdb_urls'),
    Optional[Stdlib::Unixpath]     $enc            = lookup('profile::puppetserver::enc'),
) {
    # TODO: update to use sysuseres and make a profile
    class { 'puppetmaster::gitpuppet': }
    include profile::puppetserver::git
    # TODO: configure hiera
    class { 'puppetserver':
        * => wmflib::dump_params(),
    }
    $default_sources = {
        'production'  => {
            'remote'  => $profile::puppetserver::git::control_repo_dir,
        },
    }
    # TODO: puppet-merge would need to be updated to run r10k
    # need a dependency to ensure profile::puppetserver::git before r10k
    # and r10k before puppetserver starts
    class { 'puppetserver::g10k':
        sources => $default_sources,
        require => Class['profile::puppetserver::git'],
    }
}
