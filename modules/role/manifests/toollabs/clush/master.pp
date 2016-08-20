class role::toollabs::clush::master {
    class { '::clush::master':
        username => 'clushuser',
    }
}
