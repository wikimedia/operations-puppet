# SPDX-License-Identifier: Apache-2.0

class idm::deployment (
    String           $project     = 'bitu',
    Stdlib::Unixpath $base_dir    = '/srv/idm',
    String           $deploy_user = 'www-data',
    Boolean          $development = True,
){

    # For staging and production we want to install
    # from Debian packages, but for the development
    # process the latest git version is deployed.
    if($development){
        file { $base_dir :
            ensure => directory,
            owner  => $deploy_user,
            group  => $deploy_user,
        }

        git::clone { 'operations/software/bitu':
            ensure    => 'latest',
            directory => "${base_dir}/${project}",
            branch    => 'master',
            owner     => 'www-data',
            group     => 'www-data',
            source    => 'gerrit',
        }
    }
}
