# == Class: role::debug_proxy
#
# Transparent proxy which passes requests to a set of un-pooled
# application servers that are reserved for debugging, based on
# the value of the X-Wikimedia-Debug HTTP header.
#
class role::debug_proxy {
    system::role { 'role::debug_proxy':
        description => 'X-Wikimedia-Debug proxy',
    }

    # - Allow X-Wikimedia-Debug to select mw1017 (EQIAD) and mw2017 (CODFW).
    # - For back-compat, pass 'X-Wikimedia-Debug: 1' requests to mw1017
    class { '::debug_proxy':
        backend_regexp  => '^mw[12]017',
        backend_aliases => { '1' => 'mw1017.eqiad.wmnet' },
    }
}
