# sets up a dedicated DB server for cyberbot
class role::cyberbot::db{
    require_package('mariadb-server')
}
