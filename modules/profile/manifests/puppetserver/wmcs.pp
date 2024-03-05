# SPDX-License-Identifier: Apache-2.0
class profile::puppetserver::wmcs (
    Stdlib::Unixpath $git_basedir = lookup('profile::puppetserver::git::basedir'),
){
    include profile::openstack::base::puppetmaster::enc_client
    class { 'profile::puppetserver':
        enc_path => $profile::openstack::base::puppetmaster::enc_client::enc_path,
    }
    class { 'puppetmaster::gitsync':
        base_dir => $git_basedir,
        # TODO: make git_user a param to puppetmaster::gitpuppet and use that here
        git_user => 'gitpuppet',
    }
}
