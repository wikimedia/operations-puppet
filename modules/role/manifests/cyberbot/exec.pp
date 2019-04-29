# sets up a an exec node for cyberbot
class role::cyberbot::exec{

    include ::profile::standard
    include ::profile::cyberbot::exec

    system::role { 'cyberbot::exec':
        description => 'Cyberbot Exec Node'
    }
}
