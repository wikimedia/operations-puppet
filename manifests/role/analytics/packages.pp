# == Class role::analytics::packages
# This class should be included on all analytics
# client and worker nodes.  It will install packages
# that are useful for distributed computation
# in Hadoop, and thus should be available on
# any workers, and clients for testing.
#
class role::analytics::packages {
    ensure_packages([
        'python-numpy',
        'python-pandas',
        'python-scipy',
        'python-requests',
        'python-matplotlib',
        'python-dateutil',
        'python-sympy',
        'jq',
    ])
}
