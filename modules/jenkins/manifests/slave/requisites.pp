# == Class: jenkins::slave::requisites
#
# Dependency for the Jenkins agent on slaves
#
class jenkins::slave::requisites() {

    if os_version('debian >= stretch') {
        $jdk_version = "8"
    } else {
        $jdk_version = "7"
    }

    $jdk_package = "openjdk-${jdk_version}-jre-headless"

    ensure_packages($jdk_package)
}
