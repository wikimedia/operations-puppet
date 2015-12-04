# == Class: jenkins::slave::requisites
#
# Dependency for the Jenkins agent on slaves
#
class jenkins::slave::requisites() {

    ensure_packages(['openjdk-7-jre-headless'])

}
