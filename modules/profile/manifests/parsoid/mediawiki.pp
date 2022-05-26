# SPDX-License-Identifier: Apache-2.0
# Things that are needed on a parsoid testing server
# that has MediaWiki installed but are not needed
# on a parsoid testreduce server.
class profile::parsoid::mediawiki {

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'php7.2-fpm': }
}
