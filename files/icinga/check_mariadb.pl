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
my $master_server_id = "";

my $sql_lag_warn = 30;
my $sql_lag_crit = 60;

# Warn when IO or SQL stopped cleanly (no errno)
my $warn_stopped = 0;

my $heartbeat_table = 'heartbeat.heartbeat';

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
	elsif ($arg =~ /^--warn-stopped$/)
	{
		$warn_stopped = 1;
	}
	elsif ($arg =~ /^--no-warn-stopped$/)
	{
		$warn_stopped = 0;
	}
	elsif ($arg =~ /^--master-server-id=(.+)$/)
	{
		$master_server_id = $1;
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

	unless ($status) {
		printf("%s %s not a slave", $OK, $check);
		exit($EOK);
	}

	# IO thread stopped without error, eq explicit STOP SLAVE IO_THREAD? WARN
	if ($status->{Slave_IO_Running} ne "Yes" && $status->{Last_IO_Errno} == 0) {
		if ($warn_stopped == 1) {
			printf("%s %s Slave_IO_Running: %s\n",
				$WARN, $check, $status->{Slave_IO_Running});
			exit($EWARN);
		}
		printf("%s %s Slave_IO_Running: %s, (no error; intentional)\n",
			$OK, $check, $status->{Slave_IO_Running});
		exit($EOK);
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

	unless ($status) {
		printf("%s %s not a slave", $OK, $check);
		exit($EOK);
	}

	# Both SQL and IO threads running? OK
	if ($status->{Slave_SQL_Running} eq "Yes") {
		printf("%s %s Slave_SQL_Running: %s\n",
			$OK, $check, $status->{Slave_SQL_Running});
		exit($EOK);
	}

	# SQL thread stopped without error, eq explicit STOP SLAVE SQL_THREAD? WARN
	if ($status->{Slave_SQL_Running} ne "Yes" && $status->{Last_SQL_Errno} == 0) {
		if ($warn_stopped == 1) {
			printf("%s %s Slave_SQL_Running: %s\n",
				$WARN, $check, $status->{Slave_SQL_Running});
			exit($EWARN);
		}
		printf("%s %s Slave_SQL_Running: %s, (no error; intentional)\n",
			$OK, $check, $status->{Slave_SQL_Running});
		exit($EOK);
	}

	printf("%s %s Slave_SQL_Running: No, Errno: %s, Errmsg: %s\n",
		$CRIT, $check, $status->{Last_SQL_Errno}, $status->{Last_SQL_Error});
	exit($ECRIT);
}

if ($check eq "slave_sql_lag")
{
# The slave lag is checked using the $heartbeat_table table,
# usually created and updated by running pt-heartbeat on the
# master.
# For that, --master-server-id is strongly suggested to be
# set. In case it is not, the lag from its direct master is
# reported. If the heartbeat table does not exist, the record
# for the master is not found or any other errors happens,
# it failbacks to using Seconds_Behind_Master.
# If the server is not a slave, it returns OK. If lag cannot
# be determined neither by using heartbeat nor seconds behind
# master, it returns unknown, unless the replication is 
# stopped manually- reporting optionally a warning.
	my $status = $db->selectrow_hashref("show slave status");

	unless ($status) {
		printf("%s %s not a slave", $OK, $check);
		exit($EOK);
	}

	if ($master_server_id eq "") {
		$master_server_id = $status->{Master_Server_Id};
	}
	my $heartbeat = $db->selectrow_hashref("SELECT TIMESTAMPDIFF(MICROSECOND,ts,UTC_TIMESTAMP(6)) AS lag FROM heartbeat.heartbeat WHERE server_id = $master_server_id");

	my $lag = $heartbeat->{lag}?$heartbeat->{lag}/1000000:$status->{Seconds_Behind_Master};

	if ($lag eq "NULL" or $lag eq "") {
		# Either IO or SQL threads stopped? WARN
		if ($status->{Slave_IO_Running} ne "Yes" || $status->{Slave_SQL_Running} ne "Yes") {
			if ($warn_stopped == 1) {
				printf("%s %s Slave_IO_Running: %s, Slave_SQL_Running: %s\n",
					$WARN, $check, $status->{Slave_IO_Running}, $status->{Slave_SQL_Running});
				exit($EWARN);
			}
			printf("%s %s Slave_IO_Running: %s, Slave_SQL_Running: %s, (no error; intentional)\n",
				$OK, $check, $status->{Slave_IO_Running}, $status->{Slave_SQL_Running});
			exit($EOK);
		}
		# lag could not be determined
		printf("%s %s lag could not be determined\n", $UNKN, $check);
		exit($EUNKN);

	}
	# Small lag? OK
	if ($lag < $sql_lag_warn) {
		printf("%s %s Replication lag: %.2f seconds\n",
			$OK, $check, $lag);
		exit($EOK);
	}

	# Medium lag? WARN
	if ($lag < $sql_lag_crit) {
		printf("%s %s Replication lag: %.2f seconds\n",
			$WARN, $check, $lag);
		exit($EWARN);
	}

	printf("%s %s Replication lag: %.2f seconds\n",
		$CRIT, $check, $lag);
	exit($ECRIT);
}

printf("%s %s invalid check: %s\n", $UNKN, $check, $check);
exit($EUNKN);

