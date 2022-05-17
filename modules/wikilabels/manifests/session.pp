# SPDX-License-Identifier: Apache-2.0
# == Class: wikilabels::session
#
# Defines how sessions are managed
# Currently uses memcached and may be ported to redis later
#
class wikilabels::session {

    class{ '::memcached':
        ip   => '127.0.0.1',
        port => 11211,
    }
}
