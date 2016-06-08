class contint::packages::java {

    require_package('openjdk-7-jdk')

    package { 'maven2':
        ensure => present,
    }

}
