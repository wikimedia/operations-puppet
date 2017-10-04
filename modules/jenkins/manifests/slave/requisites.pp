# == Class: jenkins::slave::requisites
#
# Dependency for the Jenkins agent on slaves
#
class jenkins::slave::requisites() {
    ensure_packages('openjdk-8-jre-headless')

    # When a slave happen to have another jre installed, make sure 8 is the
    # default.
    alternatives::select { 'java':
        path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
        require => Package['openjdk-8-jre-headless'],
    }
}
