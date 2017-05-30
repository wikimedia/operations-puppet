# == Class: jenkins::slave::requisites
#
# Dependency for the Jenkins agent on slaves
#
class jenkins::slave::requisites() {

    if os_version('ubuntu == trusty || debian == jessie') {
        ensure_packages(['openjdk-7-jre-headless'])
    }

    ensure_packages(['openjdk-8-jre-headless'])

}
