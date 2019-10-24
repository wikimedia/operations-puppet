# === Class puppet_compiler::packages
#
# Installs all the needed packages
class puppet_compiler::packages {

    $java_version = $facts['os']['release']['major'] ? {
        /10/    => '11',
        default => '8',
    }
    require_package(
        'python-yaml', 'python-requests', 'python-jinja2', 'nginx',
        'ruby-httpclient', 'ruby-ldap', 'ruby-rgen', "openjdk-${java_version}-jdk"
    )
}
