# deploy scripts and its dependencies to create replica views
class profile::wmcs::db::wikireplicas::views (
    String $view_user = lookup('profile::wmcs::db::wikireplicas::views::maintainviews::user'),
    String $view_pass = lookup('profile::wmcs::db::wikireplicas::views::maintainviews::db_pass'),
    String $idx_user  = lookup('profile::wmcs::db::wikireplicas::maintainindexes::user'),
    String $idx_pass  = lookup('profile::wmcs::db::wikireplicas::maintainindexes::db_pass'),
    Optional[Hash[String, Stdlib::Datasize]] $instances = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::instances', { 'default_value' => undef }),
){
    require ::profile::wmcs::db::scriptconfig

    ensure_packages(['wikireplicas-utils'])
    # These files are now provided by the package above
    file { '/usr/local/sbin/maintain-views': ensure => absent }
    file { '/usr/local/sbin/maintain-replica-indexes': ensure => absent }
    file { '/usr/local/sbin/maintain-meta_p': ensure => absent }
    file { '/usr/local/src/heartbeat-views.sql': ensure => absent }

    file { '/etc/maintain-views.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/maintain-views.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/etc/index-conf.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/index-conf.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }
}
