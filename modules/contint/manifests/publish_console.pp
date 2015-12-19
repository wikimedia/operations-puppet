# Dependencies for the Jenkins console publisher
# Files are made available under:
# https://integration.wikimedia.org/logs/
class contint::publish_console {

    # publish-console.py dependency
    require_package('python-requests')

}
