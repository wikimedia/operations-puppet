# === Class puppet_compiler::packages
#
# Installs all the needed packages
class puppet_compiler::packages {
    $packages = [
        'python-yaml',
        'python-requests',
        'python-jinja2',
        'nginx',
        'ruby-httpclient',
        'ruby-ldap',
        'ruby-rgen',
    ]

    require_package($packages)
}
