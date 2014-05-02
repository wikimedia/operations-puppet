#!/usr/bin/perl
#
# MariaDB 10 w/ multi-source replication Icinga checks.

use strict;
use DBI;

my $OK    = "OK";
my $EOK   = 0;
my $WARN  = "WARNING";
my $EWARN = 1;
my $CRIT  = "CRITICAL";
my $ECRIT = 2;
my $UNKN  = "UNKNOWN";
my $EUNKN = 3;

my $check = "mariadb_running";
my $host = "localhost";
my $port = "3306";
my $user = "";
my $pass = "";
my $sock = "";

my $sql_lag_warn = 30;
my $sql_lag_crit = 60;

my @vars = ();

foreach my $arg (@ARGV)
{
	if ($arg =~ /^--host=(.+)$/)
	{
		$host = $1;
	}
	elsif ($arg =~ /^--port=(.+)$/)
	{
		$port = $1;
	}
	elsif ($arg =~ /^--user=(.+)$/)
	{
		$user = $1;
	}
	elsif ($arg =~ /^--pass=(.+)$/)
	{
		$pass = $1;
	}
	elsif ($arg =~ /^--sock=(.+)$/)
	{
		$sock = $1;
	}
	elsif ($arg =~ /^--check=(.+)$/)
	{
		$check = $1;
	}
	elsif ($arg =~ /^--sql-lag-warn=(.+)$/)
	{
		$sql_lag_warn = $1;
	}
	elsif ($arg =~ /^--sql-lag-crit=(.+)$/)
	{
		$sql_lag_crit = $1;
	}
	elsif ($arg =~ /^--set=(.+)$/)
	{
		push(@vars, $1);
	}
}

my $db = DBI->connect("DBI:mysql:;host=${host};port=${port};mysql_socket=${sock}", $user, $pass);

unless ($db) {
	printf("%s %s could not connect\n",
		$CRIT, $check);
	exit($ECRIT);
}

foreach (@vars) {
	$db->do("set $_");
}

if ($check eq "mariadb_running")
{
	print("${OK} ${check} connected\n");
	exit($EOK);
}

if ($check eq "slave_io_state")
{
	my $status = $db->selectrow_hashref("show slave status");

	# IO thread stopped without error, eq explicit STOP SLAVE IO_THREAD? WARN
	if ($status->{Slave_IO_Running} ne "Yes" && $status->{Last_IO_Errno} == 0) {
		printf("%s %s Slave_IO_Running: %s\n",
			$WARN, $check, $status->{Slave_IO_Running});
		exit($EWARN);
	}

	if ($status->{Slave_IO_Running} eq "Yes") {
		printf("%s %s Slave_IO_Running: Yes\n",
			$OK, $check);
		exit($EOK);
	}

	printf("%s %s Slave_IO_Running: No, Errno: %s, Errmsg: %s",
		$CRIT, $check, $status->{Last_IO_Errno}, $status->{Last_IO_Error});
	exit($ECRIT);
}

if ($check eq "slave_sql_state")
{
	my $status = $db->selectrow_hashref("show slave status");

	# IO thread stopped? WARN
	if ($status->{Slave_IO_Running} ne "Yes") {
		printf("%s %s Slave_IO_Running: %s, Slave_SQL_Running: %s\n",
			$WARN, $check, $status->{Slave_IO_Running}, $status->{Slave_SQL_Running});
		exit($EWARN);
	}

	# Both SQL and IO threads running? OK
	if ($status->{Slave_SQL_Running} eq "Yes") {
		printf("%s %s Slave_SQL_Running: %s\n",
			$OK, $check, $status->{Slave_SQL_Running});
		exit($EOK);
	}

	# SQL thread stopped without error, eq explicit STOP SLAVE SQL_THREAD? WARN
	if ($status->{Slave_SQL_Running} ne "Yes" && $status->{Last_SQL_Errno} == 0) {
		printf("%s %s Slave_SQL_Running: %s\n",
			$WARN, $check, $status->{Slave_SQL_Running});
		exit($EWARN);
	}

	printf("%s %s Slave_SQL_Running: No, Errno: %s, Errmsg: %s\n",
		$CRIT, $check, $status->{Last_SQL_Errno}, $status->{Last_SQL_Error});
	exit($ECRIT);
}

if ($check eq "slave_sql_lag")
{
	# TODO: Make this check heartbeat

	my $status = $db->selectrow_hashref("show slave status");

	# Either IO or SQL threads stopped? WARN
	if ($status->{Slave_IO_Running} ne "Yes" || $status->{Slave_SQL_Running} ne "Yes") {
		printf("%s %s Slave_IO_Running: %s, Slave_SQL_Running: %s\n",
			$WARN, $check, $status->{Slave_IO_Running}, $status->{Slave_SQL_Running});
		exit($EWARN);
	}

	# Small lag? OK
	if ($status->{Seconds_Behind_Master} < $sql_lag_warn) {
		printf("%s %s Seconds_Behind_Master: %s\n",
			$OK, $check, $status->{Seconds_Behind_Master});
		exit($EOK);
	}

	# Medium lag? WARN
	if ($status->{Seconds_Behind_Master} < $sql_lag_crit) {
		printf("%s %s Seconds_Behind_Master: %s\n",
			$WARN, $check, $status->{Seconds_Behind_Master});
		exit($EWARN);
	}

	printf("%s %s Seconds_Behind_Master: %s\n",
		$CRIT, $check, $status->{Seconds_Behind_Master});
	exit($ECRIT);
}

printf("%s %s invalid check: %s\n", $UNKN, $check, $check);
exit($EUNKN);