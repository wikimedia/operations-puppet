# SPDX-License-Identifier: Apache-2.0
# the query service package is managed by scap
class query_service::deploy::scap(
    String $deploy_user,
    String $username,
    String $deploy_name,
    Stdlib::Absolutepath $package_dir,
) {
    # Deployment
    scap::target { 'wdqs/wdqs':
        service_name              => "${deploy_name}-blazegraph",
        deploy_user               => $deploy_user,
        additional_services_names => ["${deploy_name}-updater", "${deploy_name}-categories"],
        manage_user               => true,
    }

    # These paths are used by the scap promotion process for wdqs/wdqs, and
    # thus must be made available prior to installing the package.
    File['/var/log/query_service'] -> Package['wdqs/wdqs']
    File["/etc/${deploy_name}/vars.yaml"] -> Package['wdqs/wdqs']
    File['/etc/query_service'] -> Package['wdqs/wdqs']

    $git_deploy_dir = '/srv/deployment/wdqs/wdqs'
    if $package_dir != $git_deploy_dir {

        file { $package_dir:
            ensure  => link,
            target  => $git_deploy_dir,
            owner   => $username,
            group   => 'wikidev',
            mode    => '0775',
            require => Scap::Target['wdqs/wdqs'],
        }
    } else {
        # This is to have file resource on $package_dir in any case
        file { $package_dir:
            ensure  => present,
            owner   => $deploy_user,
            group   => $deploy_user,
            require => Scap::Target['wdqs/wdqs'],
        }
    }

}
