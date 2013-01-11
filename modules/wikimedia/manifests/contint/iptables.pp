# vim: ts=2 sw=2 expandtab
class wikimedia::contint::iptables {

  class iptables_purges {
    require '::iptables::tables'
    iptables_purge_service{  'deny_all_http-alt': service => 'http-alt' }
  }

  class iptables_accepts {
    require iptables_purges
    iptables_add_service{ 'lo_all':
      interface => 'lo',
      service   => 'all',
      jump      => 'ACCEPT'
    }
    iptables_add_service{ 'localhost_all':
      source  => '127.0.0.1',
      service => 'all',
      jump    => 'ACCEPT'
    }
    iptables_add_service{ 'private_all':
      source  => '10.0.0.0/8',
      service => 'all',
      jump    => 'ACCEPT'
    }
    iptables_add_service{ 'public_all':
      source  => '208.80.154.128/26',
      service => 'all',
      jump    => 'ACCEPT'
    }
  }

  class iptables_drops {
    require iptables_accepts
    iptables_add_service{ 'deny_all_http-alt':
      service => 'http-alt',
      jump    => 'DROP'
    }
  }

  class iptables {
    require iptables_drops
    iptables_add_exec{ $::hostname:
      service => 'http-alt'
    }
  }

  require iptables
}
