#!/usr/bin/perl

# http://nagios.sourceforge.net/docs/3_0/embeddedperl.html
# nagios: -epn

# (C) 2006-2015 by Oli Sennhauser <oli.sennhauser@fromdual.com>
# FromDual: Neutral and vendor independent consulting for MySQL,
# MariaDB and Percona Server www.fromdual.com
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA
# 02110-1301, USA.

use strict;
use warnings "all";

use DBI;
use Getopt::Long;
use File::Basename;

my $lMyName = basename($0);

my %lError = (
  'OK'       => 0
, 'Warning'  => 1
, 'Critical' => 2
, 'Unknown'  => 3
);

my $pHelp          = 0;
my $pUser          = 'check_db';
my $pPassword      = '';
my $pHost          = 'localhost';
my $lDefaultPort   = '3306';
my $lDefaultSocket = '/var/run/mysqld/mysqld.sock';
my $pNodes         = 3;

sub Usage
{
	print <<EOF;

SYNOPSIS

  $lMyName flags parameters

DESCRIPTION

  Nagios/Icinga plugin to check if a Galera Cluster for MySQL is up and running...

  For security reasons use a user with as little privileges as possible. For
  example a user called $pUser:

  GRANT USAGE ON *.* TO '$pUser'\@'$pHost' IDENTIFIED BY 'secret';

FLAGS

  --help, -?           Display this help and exit.
  --host=name, -h      Host where database to check is located (default $pHost).
  --password=name, -p  Password of user $pUser to use when connecting to server
                       $pHost (default '$pPassword').
  --port=#, -P         Port number where database listens to (default $lDefaultPort).
  --socket=name, -S    Socket file to use for connection (default
                       $lDefaultSocket).
  --user=name, -u      Check user for connecting to the database (default
                       $pUser).
  --nodes=#            Number of expected nodes (default $pNodes).

PARAMETERS

  none

EXAMPLE

  $lMyName --user=$pUser --password=secret --host=$pHost --port=$lDefaultPort --nodes=$pNodes

EOF
}

my ($pPort, $pSocket);

my $rc = GetOptions(
  'help|?'       => \$pHelp
, 'user|u=s'     => \$pUser
, 'password|p=s' => \$pPassword
, 'host|h=s'     => \$pHost
, 'port|P=i'     => \$pPort
, 'socket|S=s'   => \$pSocket
, 'nodes|n=i'    => \$pNodes
);

# On Unix, MySQL programs treat the host name localhost specially. For connec-
# tions to localhost, MySQL programs attempt to connect to the local server by
# using a Unix socket file. This occurs even if a --port or -P  option is given
# to specify a port number. To ensure that the client makes a TCP/IP connection
# to the local server, use --host or -h to specify a host name value of
# 127.0.0.1, or the IP address or name of the local server.
#
# Lit: refman-5.6-en.html-chapter/programs.html

my $lConnectionMethod = 'socket';

if ( ! defined($pHost) || $pHost eq '' ) {
	$pHost = 'localhost';
}
if ( $pHost eq 'localhost' ) {
	if ( defined($pPort) && $pPort ne '' ) {
		print("Port is overspecified when using host=localhost.");
		exit($lError{'Warning'});
	}
	if ( ! defined($pSocket) || $pSocket eq '' ) {
		$pSocket = $lDefaultSocket;
	}
	$lConnectionMethod = 'socket';
}
# host != localhost
else {
	if ( defined($pSocket) && $pSocket ne '' ) {
		print("Socket is overspecified when using host=localhost.");
		exit($lError{'Warning'});
	}
	if ( ! defined($pPort) || $pPort eq '' ) {
		$pPort = $lDefaultPort;
	}
	$lConnectionMethod = 'port';
}

# Nodes not specfied or values out of range (<2 > 64)

if ( ($pNodes < 2) || ($pNodes > 128) ) {
	print "Number for Galera Cluster nodes is out of expected range (2...128): $pNodes\n";
	exit($lError{'Warning'});
}

if ( $pHelp ) {
	&Usage();
	exit($lError{'OK'});
}

if ( ! $rc ) {
	print("Error in parameters. User = $pUser, Password=hidden, Host = $pHost, Port = $pPort, Socket = $pSocket");
	exit($lError{'Unknown'});
}

if ( @ARGV != 0 ) {
	print("Error in parameters. To many arguments: @ARGV");
	exit($lError{'Unknown'});
}

# Start here
# ----------

my ($dbh, $sql, $sth);

my $lTimeout = 10;
my $dsn;
if ( $lConnectionMethod eq 'socket' ) {
	$dsn = "DBI:mysql::mysql_socket=$pSocket;mysql_connect_timeout=$lTimeout";
}
else {
	$dsn = "DBI:mysql::host=$pHost:port=$pPort;mysql_connect_timeout=$lTimeout";
}
$dbh = DBI->connect($dsn, $pUser, $pPassword
	, { RaiseError => 0
	, PrintError => 0
	, AutoCommit => 0
		}
);

if ( DBI::err ) {

	if ( DBI::errstr =~ m/Can't connect to/ ) {
		print("Error during connection: " . DBI::errstr);
		exit($lError{'Critical'});
	}

	if ( DBI::errstr =~ m/Access denied for user/ ) {
		print("User does not have access privileges to database: " . DBI::errstr);
		exit($lError{'Warning'});
	}

	print("Error during connection: " . DBI::errstr);
	exit($lError{'Critical'});
}

$sql = "
	SHOW GLOBAL STATUS WHERE variable_name in ('wsrep_cluster_size', 'wsrep_cluster_status')
";

$sth = $dbh->prepare( $sql );
if ( DBI::err ) {
	print("Error in preparing: " . DBI::errstr);
	$dbh->disconnect;
	exit($lError{'Critical'});
}

$sth->execute();
if ( $sth->err ) {
	print("Error in executing: " . $sth->errstr);
	$dbh->disconnect;
	exit($lError{'Critical'});
}

my ($lKey, $lValue);
$sth->bind_columns(undef, \$lKey, \$lValue);
if ( $sth->err ) {
	print("Error in binding: " . $sth->errstr);
	$sth->finish;
	$dbh->disconnect;
	exit($lError{'Critical'});
}

my %aStatus;
while ( $sth->fetchrow_arrayref() ) {
	$aStatus{$lKey} = $lValue;
}
if ( $sth->err ) {
	print("Error in fetchting:" . $sth->err);
	$sth->finish;
	$dbh->disconnect;
	exit($lError{'Critical'});
}
$sth->finish;

if ( ! defined($aStatus{'wsrep_cluster_status'}) ) {
	print "Caution: It looks like this is NOT a Galera cluster. The variable wsrep_cluster_status is not defined.\n";
	$dbh->disconnect;
	exit($lError{'Warning'});
}

if ( $aStatus{'wsrep_cluster_status'} eq "Primary" ) {

	if ( $aStatus{'wsrep_cluster_size'} == $pNodes ) {
		print "OK wsrep_cluster_size: " . $aStatus{'wsrep_cluster_size'} . ", wsrep_cluster_status: " . $aStatus{'wsrep_cluster_status'} . "\n";
		$dbh->disconnect;
		exit($lError{'OK'});
	}
	else {
		print "Caution: wsrep_cluster_size: " . $aStatus{'wsrep_cluster_size'} . ", wsrep_cluster_status: " . $aStatus{'wsrep_cluster_status'} . "\n";
		$dbh->disconnect;
		exit($lError{'Warning'});
	}
}
else {
	print "Caution: wsrep_cluster_status: " . $aStatus{'wsrep_cluster_status'} . "\n";
	$dbh->disconnect;
	exit($lError{'Critical'});
}

print "Galera Cluster for MySQL seems OK...";
exit($lError{'OK'});
