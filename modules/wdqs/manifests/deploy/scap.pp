# the wdqs package is managed by scap
class wdqs::deploy::scap(
    String $deploy_user,
    String $username,
    Stdlib::Absolutepath $package_dir,
) {
    # Deployment
    scap::target { 'wdqs/wdqs':
        service_name              => 'wdqs-blazegraph',
        deploy_user               => $deploy_user,
        additional_services_names => ['wdqs-updater', 'wdqs-categories'],
        manage_user               => true,
    }

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
            require => Scap::Target['wdqs/wdqs'],
        }
    }

}