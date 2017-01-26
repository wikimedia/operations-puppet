# = Class: ifttt::base
# Base class that sets up packages
class ifttt::base(
    $source_path = '/srv/ifttt',
    $venv_path = '/srv/ifttt/venv',
) {
    # Let's use a virtualenv for maximum flexibility - we can convert
    # the pip requirements to deb packages in the future if needed.
    ensure_packages([
        'virtualenv',
        'gcc',
        'python-dev',
        'libmysqlclient-dev',
        'libxml2-dev',
        'libxslt1-dev',
    ])

}
