class contint::packages::java {

    require_package('openjdk-8-jdk')

    alternatives::select { 'java':
        path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
        require => Package['openjdk-8-jdk'],
    }

    package { 'maven2':
        ensure => present,
    }

}
