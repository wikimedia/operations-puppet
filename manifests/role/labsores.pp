class role::labs::ores::web {
    include ::ores::web
}

class role::labs::ores::lb(
    $realservers,
) {
    require role::labs::lvm::srv

    class { '::ores::lb':
        realservers => $realservers,
    }
}
