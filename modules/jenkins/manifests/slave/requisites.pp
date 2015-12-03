# == Class: jenkins::slave::requisites
#
# Resources commons to all slaves, either in production or in labs
#
class jenkins::slave::requisites() {

    ensure_packages(['openjdk-7-jre-headless'])

    include phabricator::arcanist

}
