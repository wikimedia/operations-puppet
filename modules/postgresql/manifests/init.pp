# Base PG class
class postgresql {
	package { "postgresql":
		ensure => latest;
	}

	service { "postgresql":
		name => postgresql,
		ensure => running,
		enable => true,
	}
}

# Base SQL exec
define postgresql::sqlexec($database, $sql, $sqlcheck) {
	exec{ "echo \"$sql\" | psql $database":
		timeout => 600,
		user => "postgres",
		path => "/usr/bin:/bin",
		unless => "echo \"$sqlcheck\" | psql $database\" | grep \"(1 row)\"",
		require => Class["postgresql"],
	}
}

# Base SQL file exec
define postgresql::sqlfileexec($database, $sql, $sqlcheck) {
    exec{ "psql -d $database -f $sql":
        timeout => 600,
        user => "postgres",
        path => "/usr/bin:/bin",
        unless => "echo \"$sqlcheck\" | psql $database | grep \"(1 row)\"",
        require => Class["postgresql"],
    }
}

#Create a Postgres user role
define postgresql::createuser() {
	postgresql::sqlexec{ "createuser-$name":
		database => "postgres",
		sql => "CREATE USER \\\"$name\\\";",
		sqlcheck => "SELECT usename FROM pg_catalog.pg_user WHERE usename = '$name';",
	}
}

# Create a Postgres db
define postgresql::createdb($sqlowner) {
	postgresql::sqlexec{ "createdb-$name":
		database => "postgres",
		sql => "CREATE DATABASE \\\"$name\\\" WITH OWNER = \\\"$sqlowner\\\" ENCODING = 'UTF8' TEMPLATE=template0;",
		sqlcheck => "SELECT datname FROM pg_database WHERE datname = '$name'",
	}
}

