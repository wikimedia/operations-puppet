# sets up a an exec node for cyberbot
class role::cyberbot::exec{
    include profile::base::production
    include profile::cyberbot::exec
}
