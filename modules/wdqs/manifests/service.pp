# == Class: wdqs::service
#
# Provisions WDQS service package
#
class wdqs::service(
    $deploy_user,
    $package_dir,
    $username,
    $config_file='RWStore.properties',
) {

    include ::wdqs::packages

    if $::wdqs::use_git_deploy {

        # Deployment
        scap::target { 'wdqs/wdqs':
            service_name => 'wdqs-blazegraph',
            deploy_user  => $deploy_user,
            manage_user  => true,
        }

        $git_deploy_dir = '/srv/deployment/wdqs/wdqs'
        if $package_dir != $git_deploy_dir {

            file { $package_dir:
                ensure  => link,
                target  => $git_deploy_dir,
                owner   => $::wdqs::username,
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

    } else {
        file { $package_dir:
            ensure  => present,
            owner   => $username,
            group   => 'wikidev',
            mode    => '0775',
            require => User[$username],
        }

        ## don't do anything else

    }

    # Blazegraph service
    base::service_unit { 'wdqs-blazegraph':
        template_name  => 'wdqs-blazegraph',
        systemd        => true,
        upstart        => true,
        service_params => {
            enable => true,
        }
    }
}
