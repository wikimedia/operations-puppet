# SPDX-License-Identifier: Apache-2.0
# == Class: wikilabels::db_proxy
#
# Adds a hostname and ip entry to /etc/hosts for the db server
#
class wikilabels::db_proxy(
    $server,
) {
    host { 'wikilabels-database':
        ensure => present,
        ip     => dnsquery::a($server)[0]
    }
}
