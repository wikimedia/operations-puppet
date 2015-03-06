# https://dev.wikimedia.org/
# developer portal page - T308
class role::devportal {

    system::role { 'role::devportal': description => 'dev.wikimedia.org' }

    include ::devportal

    ferm::service { 'devportal_http':
        proto => 'tcp',
        port  => '80',
    }

}

