# sets up a dedicated DB server for cyberbot
class profile::cyberbot::db{
    require_package('mariadb-server')
}
