# SPDX-License-Identifier: Apache-2.0
# https://we.phorge.it - fork of Phabricator
class profile::phorge(
    String $server_name = lookup('profile::phorge::server_name'),
    Stdlib::Unixpath $install_path_arcanist = lookup('profile::phorge::install_path_arcanist'),
    Stdlib::HTTPSUrl $git_origin_arcanist = lookup('profile::phorge::git_origin_arcanist'),
    Stdlib::Unixpath $install_path_phorge = lookup('profile::phorge::install_path_phorge'),
    Stdlib::HTTPSUrl $git_origin_phorge = lookup('profile::phorge::git_origin_phorge'),
){

    ensure_packages([
        'libapache2-mod-php',
        'git',
        'php-mbstring',
        'php-curl',
        'php-mysql',
        'php-zip',
        'php-gd',
    ])

    $httpd_modules = ['rewrite', 'headers', 'php7.4']

    class { 'httpd::mpm':
        mpm    => 'prefork',
    }

    class { 'httpd':
        modules             => $httpd_modules,
        purge_manual_config => false,
        require             => Class['httpd::mpm'],
    }

    $document_root = "${install_path_phorge}/webroot"

    httpd::site { 'phorge':
        content => template('profile/phorge/httpd.conf.erb'),
    }

    wmflib::dir::mkdir_p([$install_path_arcanist, $install_path_phorge])

    git::clone { 'arcanist':
        ensure    => 'present',
        origin    => $git_origin_arcanist,
        directory => $install_path_arcanist,
        branch    => 'master',
    }

    git::clone { 'phorge':
        ensure    => 'present',
        origin    => $git_origin_phorge,
        directory => $install_path_phorge,
        branch    => 'master',
    }

}
