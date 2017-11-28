# sets up a database node for cyberbot
class role::cyberbot::db{

    include ::standard
    include ::profile::cyberbot::db

    system::role { 'cyberbot::db':
        description => 'Cyberbot Database Node'
    }
}
