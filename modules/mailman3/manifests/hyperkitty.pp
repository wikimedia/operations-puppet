# == Class mailman3::hyperkitty
#
# Installs the django web app serving hyperkitty (mailman archiver) to users
class mailman3::hyperkitty (
    String $archiver_key,
) {

    ensure_packages([
        'python3-pymysql',
        'dbconfig-mysql',
        # https://hyperkitty.readthedocs.io/en/latest/install.html#install-the-code
        'sassc',
        'python3-django-hyperkitty'
    ])

    file { '/etc/mailman3/mailman-hyperkitty.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mailman3/mailman-hyperkitty.cfg.erb'),
    }
}
