#!/usr/bin/perl

use strict;
use DBI;
use Socket;
use Digest::MD5 qw(md5 md5_hex md5_base64);

my $dbi = "DBI:mysql:;mysql_read_default_file=./tendril.cnf;mysql_read_default_group=tendril";
my $db  = DBI->connect($dbi, undef, undef) or die("db?");
$db->do("SET NAMES 'utf8';");

my $servers = $db->prepare("select id, host, port from servers");

$servers->execute();

while (my $row = $servers->fetchrow_hashref())
{
	my $server_id = $row->{id};
	my $host = $row->{host};
	my $port = $row->{port};

	my ($lock) = $db->selectrow_array("select get_lock('tendril-cron-5m-$server_id', 1)");

	if ($lock == 1)
	{
		print "$host:$port\n";

		my $select = $db->prepare("select id, host, info, md5(info) as info_md5 from processlist_query_log where server_id = ? and info is not null and checksum is null and stamp > now() - interval 3 day group by id, host, info");
		if ($select->execute($server_id))
		{
			while (my $row = $select->fetchrow_hashref())
			{
				if ($row->{host} =~ /^(\d+\.\d+\.\d+\.\d+):\d+$/)
				{
					my $ipv4 = $1;
					my $iaddr = inet_aton($ipv4);
					if (my $host = gethostbyaddr($iaddr, AF_INET))
					{
						my $replace = $db->prepare("replace into dns (host, ipv4) values (?, ?)");
						$replace->execute($host, $ipv4);
						$replace->finish();
					}
				}

				my $query = $row->{info};
				$query =~ s/"(?:[^"\\]|\\.)*"/?/ig;
				$query =~ s/'(?:[^'\\]|\\.)*'/?/ig;
				$query =~ s/\b([0-9]+)\b/?/ig;
				$query =~ s/\/\*.*?\*\///ig;
				$query =~ s/\s+/ /ig;
				$query =~ s/^\s+//ig;
				$query =~ s/\s+$//ig;
				$query =~ s/[(][?,'" ]+?[)]/?LIST?/g;


				my $update = $db->prepare("update processlist_query_log set checksum = md5(?) where server_id = ? and id = ? and checksum is null and md5(info) = ? and stamp > now() - interval 3 day");
				my $rs = $update->execute($query, $server_id, $row->{id}, $row->{info_md5});
				$update->finish();

				print ".";
			}
		}
		print "\n";
		$select->finish();

		if (my $ipv4packed = gethostbyname($host))
		{
			my $ipv4 = inet_ntoa($ipv4packed);

			my $update = $db->prepare("update servers set ipv4 = ? where id = ?");
			$update->execute($ipv4, $server_id);
			$update->finish();

			my $replace = $db->prepare("replace into dns (host, ipv4) values (?, ?)");
			$replace->execute($host, $ipv4);
			$replace->finish();
		}

		$db->do("select release_lock('tendril-cron-5m-$server_id')");
	}
}
$servers->finish();
