# == Class: jenkins::slave::requisites
#
# Resources commons to all slaves, either in production or in labs
#
class jenkins::slave::requisites() {

    package { 'openjdk-7-jre-headless':
        ensure => present,
    }

}
