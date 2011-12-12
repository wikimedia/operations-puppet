#Initialize variables
$mysql_password = "myT0pS3cretPa55worD"

#Initialize directories
file{'~/downloads':
	ensure => 'directory'
	}

file{'/srv/reportcard':
	ensure => 'directory'
	}
	
file{'/srv/reportcard/staging':
	ensure => 'directory'
	}

file{'/srv/reportcard/staging':
		ensure => 'directory'
	}

file{'/srv/reportcard/production':
		ensure => 'directory'
	}

file{'/srv/reportcard/staging/logs':
		ensure => 'directory',
		owner => 'www-data',
		group => 'www-data',
	}

file{'/srv/reportcard/production/logs':
		ensure => 'directory',
		owner => 'www-data',
		group => 'www-data',
	}

file{'/srv/reportcard/production/webapp':
		ensure => 'directory',
		owner => 'www-data',
		group => 'www-data',
	}


file{'/srv/reportcard/staging/webapp':
		ensure => 'directory',
		owner => 'www-data',	
		group => 'www-data',
	}


file{'/mnt/sqldata':
		ensure => 'directory'
	}

file{'/mnt/tmp':
		ensure => 'directory'
	}


#Download Mediawiki
define download_file(
	$site ='',
	$creates='',
	) {
	exec {$name:
	command => "wget ${site}/${name}",
	creates => "~/downloads/${name}",
	}
	
}

download_file{}[mediawiki-1.18.0.tar.gz]:
	site => "http://download.wikimedia.org/mediawiki/1.18/",
	cwd => "~/downloads/",
}


#Install Apache2
class apache::install {
	package {["apache2"]:
	ensure =>present,
	}
}

#Configure Apache2
class apache::service {
	service {"apache2":
		ensure => running,
		hasstatus =>true,
		hasrestart => true,
		enable => true,
		require => Class["apache::install"],
		}
}

#Install MySQL
class mysql::install {
	package {"mysql-server": ensure => installed}
	package {"mysql": ensure=>installed}
	
	service { "mysqld":
		enable=> true,
		ensure=>running,
		require => Package["mysql-server"],
	}
	
	file { "/var/lib/mysql/my.cnf":
    owner => "mysql", group => "mysql",
    source => "puppet:///mysql/my.cnf",
    notify => Service["mysqld"],
    require => Package["mysql-server"],
  }

  file { "/etc/my.cnf":
    require => File["/var/lib/mysql/my.cnf"],
    ensure => "/var/lib/mysql/my.cnf",
  }

  exec { "set-mysql-password":
    unless => "mysqladmin -uroot -p$mysql_password status",
    path => ["/bin", "/usr/bin"],
    command => "mysqladmin -uroot password $mysql_password",
    require => Service["mysqld"],
}

define mysqldb( $user, $password ) {
  exec { "create-${name}-db":
    unless => "/usr/bin/mysql -u${user} -p${password} ${name}",
    command => "/usr/bin/mysql -uroot -p$mysql_password -e \"create database ${name}; grant all on ${name}.* to ${user}@localhost identified by '$password';\"",
    require => Service["mysqld"],
  }
}

#install PHP

class php {
  package { [ "php", "php-mysql"]:
    ensure => installed,
  }
  
  file { "/etc/php.ini":
    source => "puppet:///php/php.ini",
  }
}

class reportcard::db {
	mysqldb {"reportcard":
		user => "reportcard_user",
		password => "r3p0rtc@rd",
		}
}

class reportcard {
	include reportcard::db

}