# SPDX-License-Identifier: Apache-2.0
# Things that are needed on a parsoid testing server
# that has MediaWiki installed but are not needed
# on a parsoid testreduce server.
class profile::parsoid::mediawiki {

    $php_version = wmflib::wmf_php_version()
    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { "php${php_version}-fpm": }
    profile::auto_restarts::service { 'envoyproxy': }
}
