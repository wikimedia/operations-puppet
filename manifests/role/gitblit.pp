# manifests/role/gitblit.pp

class role::gitblit {
    system::role { 'role::gitblit': description => 'Gitblit, a git viewer' }

    include role::gerrit::production::replicationdest

    class { '::gitblit':
        host => 'git.wikimedia.org',
    }

    # Firewall GitBlit, it should be accessed from localhost or Varnish
    ferm::rule { 'gitblit_8080':
        rule => 'proto tcp dport 8080 { saddr $INTERNAL ACCEPT; }'
    }

    nrpe::monitor_service { 'gitblit_process':
        description  => 'gitblit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/bin/java .*-jar gitblit.jar'"
    }
}
