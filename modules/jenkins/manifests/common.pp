# == Class: jenkins::common
#
# Dependency common to master and slaves
#
class jenkins::common {
    case $facts['os']['release']['major'] {
        /10/: {
            $java_version = '11'
            $java_headless = 'openjdk-11-jre-headless'
            $java_alt_path = '/usr/lib/jvm/java-11-openjdk-amd64/bin/java'
        } default: {
            $java_version = '8'
            $java_headless = 'openjdk-8-jre-headless'
            $java_alt_path = '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java'
        }
    }
    ensure_packages($java_headless)

    alternatives::select { 'java':
        path    => $java_alt_path,
        require => Package[$java_headless],
    }
}
