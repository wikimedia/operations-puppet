# SPDX-License-Identifier: Apache-2.0
# Things that are needed on a parsoid testing server
# that has MediaWiki installed but are not needed
# on a parsoid testreduce server.
class profile::parsoid::mediawiki(
    Array[Wmflib::Php_version] $php_versions = lookup('profile::mediawiki::php::php_versions'),
    Array[Wmflib::Php_version] $absented_php_versions = lookup('profile::mediawiki::php::absented_php_versions', {'default_value' => []}),
) {

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }
    $php_versions.each |$php_version| {
        profile::auto_restarts::service { "php${php_version}-fpm": }
    }
    $absented_php_versions.each |$php_version| {
        profile::auto_restarts::service { "php${php_version}-fpm":
            ensure => absent,
        }
    }

}
