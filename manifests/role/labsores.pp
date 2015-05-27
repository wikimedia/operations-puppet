class role::labs::ores::web {
    include ::ores::web
}

class role::labs::ores::lb(
    $realservers,
) {
    class { '::ores::lb':
        realserveres => $realservers,
    }
}
