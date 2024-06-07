# sets up a database node for cyberbot
class role::cyberbot::db{
    include profile::base::production
    include profile::cyberbot::db
}
