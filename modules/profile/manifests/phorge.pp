# SPDX-License-Identifier: Apache-2.0
# https://we.phorge.it - fork of Phabricator
class profile::phorge(
    String $server_name = lookup('profile::phorge::server_name'),
    Stdlib::Unixpath $install_path = lookup('profile::phorge::install_path'),
    Stdlib::HTTPSUrl $git_origin = lookup('profile::phorge::git_origin'),
){

    wmflib::dir::mkdir_p($install_path)

    git::clone { 'phorge':
        ensure    => 'present',
        origin    => $git_origin,
        directory => $install_path,
        branch    => 'master',
    }

    $document_root = "${install_path}/webroot"

    httpd::site { 'phorge':
        content => template('profile/phorge/apache.conf.erb'),
    }

}
