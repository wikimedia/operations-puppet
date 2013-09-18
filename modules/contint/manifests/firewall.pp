class contint::firewall {

  # prevent users from accessing port 8080 directly (but still allow from
  # localhost and own net)

  class iptables-purges {

    require 'iptables::tables'

    iptables_purge_service{  'deny_all_http-alt': service => 'http-alt' }
    iptables_purge_service{  'deny_all_zuul-daemon': service => 'zuul_webservice' }
    iptables_purge_service{  'deny_all_git-daemon': service  => 'git_daemon' }
  }

  class iptables-accepts {

    require 'contint::firewall::iptables-purges'

    iptables_add_service{ 'lo_all': interface => 'lo', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'localhost_all': source => '127.0.0.1', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_all': source => '10.0.0.0/8', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_all': source => '208.80.152.0/22', service => 'all', jump => 'ACCEPT' }
  }

  class iptables-drops {

    require 'contint::firewall::iptables-accepts'

    iptables_add_service{ 'deny_all_http-alt': service => 'http-alt', jump => 'DROP' }
    # Deny direct access to the Zuul daemon
    iptables_add_service{ 'deny_all_zuul-daemon': service => 'zuul_webservice', jump => 'DROP' }
    # Deny git daemon listening on port 9418
    iptables_add_service{ 'deny_all_git-daemon': service => 'git_daemon', jump => 'DROP' }
  }

  class iptables {

    require 'contint::firewall::iptables-drops'

    iptables_add_exec{ $::hostname: service => 'contint' }
  }

  require contint::firewall::iptables
}
