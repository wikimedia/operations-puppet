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

    # Backward compatibility
    $aliases = {
        '1'                  => 'mwtest1001.eqiad.wmnet',
        'mw1017.eqiad.wmnet' => 'mwtest1001.eqiad.wmnet',
        'mw1099.eqiad.wmnet' => 'mwtest1002.eqiad.wmnet',
    }

    # - Allow X-Wikimedia-Debug to select mw1017 and mw1099 in EQIAD
    #   and mw2017 and mw2099 in CODFW.
    # - For back-compat, pass 'X-Wikimedia-Debug: 1' requests to mw1017.
    class { '::debug_proxy':
        backend_regexp  => '^((mwtest1001|mwtest1002)\.eqiad\.wmnet|(mw2017|mw2099)\.codfw\.wmnet)',
        backend_aliases => $aliases,
        resolver        => join($::nameservers, ' '),
    }
    # lint:endignore

    ferm::service { 'debug_proxy':
        proto  => 'tcp',
        port   => '80',
        srange => '$PRODUCTION_NETWORKS',
    }
}
