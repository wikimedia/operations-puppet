# Manifest to setup a Gerrit instance
class gerrit(
    $config,
    $domain,
    $slave_hosts = [],
    $slave = false,
) {

    class { '::gerrit::jetty':
        slave  => $slave,
        config => $config,
    }

    class { '::gerrit::proxy':
        require     => Class['gerrit::jetty'],
        slave_hosts => $slave_hosts,
        slave       => $slave,
        domain      => $domain,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
