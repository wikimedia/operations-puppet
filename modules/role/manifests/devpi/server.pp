# Sets up a simple devpi server
class role::devpi::server {
    require role::labs::lvm::srv

    class {'::devpi':}
}
