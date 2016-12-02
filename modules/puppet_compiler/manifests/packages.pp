# === Class puppet_compiler::packages
#
# Installs all the needed packages
class puppet_compiler::packages {
    include puppetmaster::enc

    require_package('python-yaml', 'python-requests', 'python-jinja2', 'nginx', 'ruby-httpclient', 'ruby-ldap')

}
