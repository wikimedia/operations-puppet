class role::labs::ores::web {
    include ::ores::web
}

class role::labs::ores::lb(
    $realservers,
) {
    labs_lvm::volume { 'srv':
        mountat => '/srv',
    }

    class { '::ores::lb':
        realservers => $realservers,
        require     => Labs_lvm::Volume['srv'],
    }
}

class role::labs::ores::staging {
    include ::ores::web
    class { '::ores::lb':
        realservers => [ 'localhost:8080' ],
        cached      => false,
    }
