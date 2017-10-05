class contint::packages::java {

    include ::jenkins::common

    require_package('openjdk-8-jdk')

    package { 'maven2':
        ensure => present,
    }

}
