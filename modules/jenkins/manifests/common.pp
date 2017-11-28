# == Class: jenkins::common
#
# Dependency common to master and slaves
#
class jenkins::common {
    ensure_packages('openjdk-8-jre-headless')

    alternatives::select { 'java':
        path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
        require => Package['openjdk-8-jre-headless'],
    }
}
