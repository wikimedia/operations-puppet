# == Class: wdqs::service
#
# Provisions WDQS service package
#
class wdqs::service(
    $package_dir=$::wdqs::package_dir,
    $username=$::wdqs::username,
    $config_file='RWStore.properties',
) {

    include ::wdqs::packages

    if $::wdqs::use_git_deploy {

        package { 'wdqs':
            ensure   => present,
            provider => 'trebuchet',
            require  => User[$username],
        }

        $git_deploy_dir = '/srv/deployment/wdqs/wdqs'
        if $package_dir != $git_deploy_dir {

            file { $package_dir:
                ensure  => link,
                target  => $git_deploy_dir,
                owner   => $::wdqs::username,
                group   => 'wikidev',
                mode    => '0775',
                require => Package['wdqs'],
            }
        } else {
            # This is to have file resource on $package_dir in any case
            file { $package_dir:
                ensure  => present,
                require => Package['wdqs'],
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
        },
    }
}
