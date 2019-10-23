# == Class: jenkins::common
#
# Dependency common to master and slaves
#
class jenkins::common {
    $java_version = $facts['os']['lsb']['distcodename'] ? {
        'buster' => '11',
        default  => '8',
    }
    ensure_packages("openjdk-${java_version}-jre-headless")

    alternatives::select { 'java':
        path    => "/usr/lib/jvm/java-${java_version}-openjdk-amd64/jre/bin/java",
        require => Package["openjdk-${java_version}-jre-headless"],
    }
}
