# ishmael web app
#
# NOTE: this does not install ishmael.. it could be git deployed, but it hasn't been moved to a wmf repo. for now:
# cd /srv ; git clone https://github.com/asher/ishmael.git ; cd ishmael ; git clone https://github.com/asher/ishmael.git sample
#
class ishmael {

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/etc/apache2/sites-available/ishmael.wikimedia.org':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('apache/ishmael.wikimedia.org.erb');
    }

    apache_site { 'ishmael': name => 'ishmael.wikimedia.org' }

    ishmael::config { '/srv/ishmael/conf.php': }

    ishmael::config { '/srv/ishmael/sample/conf.php':
        review_table  => '%tcpquery_review',
        history_table => '%tcpquery_review_history',
    }
}
