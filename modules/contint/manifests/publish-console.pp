# Dependencies for the Jenkins console publisher
# Files are made available under:
# https://integration.wikimedia.org/logs/
class contint::publish-console {

    # publish-console.py dependencies
    if ! defined ( Package['python-requests'] ) {
        package { 'python-requests':
            ensure => present,
        }
    }

}
