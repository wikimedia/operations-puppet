# the wdqs package is checked out initially, but not automatically upgraded
class wdqs::deploy::manual(
    String $deploy_user,
    Stdlib::Absolutepath $package_dir,
) {
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
    }

    # git clone needs to be executed before any files are created in the package dir
    # and for some deployment types, the data dir is in the package dir
    Git::Clone['wdqs_git_clone'] -> File<| tag == 'in-wdqs-data-dir' |>
    Git::Clone['wdqs_git_clone'] -> File<| tag == 'in-wdqs-package-dir' |>


    exec { 'wdqs_git_fat_init':
        path    => '/usr/bin:/bin',
        cwd     => $package_dir,
        command => 'git fat init',
        user    => $deploy_user,
        group   => $deploy_user,
        onlyif  =>
            'test -z $(git config --get filter.fat.clean) && test -z $(git config --get filter.fat.smudge)',
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

    [ 'wdqs-blazegraph', 'wdqs-categories', 'wdqs-updater'].each |String $service_name| {
        sudo::user { "${deploy_user}_${service_name}":
            user       => $deploy_user,
            privileges => [
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} start",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} stop",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} restart",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} reload",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} status",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} try-restart",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} force-reload",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} graceful-stop"
            ],
        }
    }

}