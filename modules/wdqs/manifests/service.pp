# == Class: wdqs::service
#
# Provisions WDQS service package
#
class wdqs::service(
    String $deploy_user,
    Stdlib::Absolutepath $package_dir,
    String $username,
    String $config_file,
    String $logstash_host,
    Wmflib::IpPort $logstash_json_port,
    Stdlib::Absolutepath $log_dir,
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

        if !defined(Group[$deploy_user]) {
            group { $deploy_user:
                ensure => present,
                system => true,
                before => User[$deploy_user],
            }
        }

        if !defined(User[$deploy_user]) {
            user { $deploy_user:
                ensure => present,
                shell  => '/bin/bash',
                home   => "/var/lib/${deploy_user}",
                system => true,
            }
            file { "/var/lib/${deploy_user}":
                ensure => 'directory',
                owner  => $deploy_user,
                group  => $deploy_user,
                mode   => '0755',
            }
        }

        if !defined(Ssh::Userkey[$deploy_user]) {
            $key_name_safe = regsubst($deploy_user, '\W', '_', 'G')

            ssh::userkey { $deploy_user:
                ensure  => 'present',
                content => secret("keyholder/${key_name_safe}.pub"),
            }
        }

        git::clone { 'wdqs_git_clone':
            ensure             => present,
            owner              => $deploy_user,
            group              => $deploy_user,
            directory          => $package_dir,
            origin             => 'https://gerrit.wikimedia.org/r/wikidata/query/deploy',
            branch             => 'master',
            recurse_submodules => true,
            before             => File["${package_dir}/rules.log"],
        }

        exec { 'wdqs_git_fat_init':
            path    => '/usr/bin:/bin',
            cwd     => $package_dir,
            command => 'git fat init',
            user    => $deploy_user,
            group   => $deploy_user,
            onlyif  => '! git config --get filter.fat.clean || git config --get filter.fat.smudge',
            require => Git::Clone['wdqs_git_clone'],
        }

        # an uninitialized git-fat file is 74 bytes (the length of the SHA)
        exec { 'wdqs_git_fat_pull':
            path    => '/usr/bin:/bin',
            cwd     => $package_dir,
            command => 'git fat pull',
            user    => $deploy_user,
            group   => $deploy_user,
            onlyif  => 'test $(stat -c%s blazegraph-service-*.war) -eq 74',
            require => Exec['wdqs_git_fat_init'],
        }

        sudo::user { 'deploy-service_blazegraph':
            user       => $deploy_user,
            privileges => [
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph start',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph stop',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph restart',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph reload',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph status',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph try-restart',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph force-reload',
                'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-blazegraph graceful-stop'
            ],
        }

        $wdqs_autodeployment_log = "${log_dir}/wdqs_autodeployment.log"

        file { '/usr/local/bin/wdqs-autodeploy':
            ensure => present,
            source => 'puppet:///modules/wdqs/cron/wdqs-autodeploy.sh',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        cron { 'wdqs-autodeploy':
            ensure  => present,
            command => "/usr/local/bin/wdqs-autodeploy ${package_dir} >> ${$wdqs_autodeployment_log} 2>&1",
            user    => $username,
            hour    => [5, 11, 17, 23],
        }

        logrotate::rule { 'wdqs_autodeployment_log':
            ensure       => present,
            file_glob    => $wdqs_autodeployment_log,
            frequency    => 'daily',
            missing_ok   => true,
            not_if_empty => true,
            rotate       => 30,
            compress     => true,
        }
    }

    # Blazegraph service
    systemd::unit { 'wdqs-blazegraph':
        content => template('wdqs/initscripts/wdqs-blazegraph.systemd.erb'),
    }

    service { 'wdqs-blazegraph':
        ensure => 'running',
    }
}
