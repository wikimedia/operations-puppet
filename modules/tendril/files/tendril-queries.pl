#!/usr/bin/perl

use strict;
use DBI;
use Socket;
use Digest::MD5 qw(md5 md5_hex md5_base64);

my $config = $ARGV[0];

my $dbi = "DBI:mysql:;mysql_read_default_file=$config;mysql_read_default_group=tendril";
my $db  = DBI->connect($dbi, undef, undef) or die("db?");
$db->do("SET NAMES 'utf8';");

my $select = $db->prepare("select checksum, content from queries where footprint is null");
if ($select->execute())
{
    while (my $row = $select->fetchrow_hashref())
    {
        my $query = $row->{content};
        $query =~ s/"(?:[^"\\]|\\.)*"/?/ig;
        $query =~ s/'(?:[^'\\]|\\.)*'/?/ig;
        $query =~ s/\b([0-9]+)\b/?/ig;
        $query =~ s/\/\*.*?\*\///ig;
        $query =~ s/\s+/ /ig;
        $query =~ s/^\s+//ig;
        $query =~ s/\s+$//ig;
        $query =~ s/[(][?,'" ]+?[)]/?LIST?/g;


        my $update = $db->prepare("update queries set footprint = md5(?), template = ? where checksum = ?");
        my $rs = $update->execute($query, $query, $row->{checksum});
        $update->finish();

        print $row->{content}."\n";
    }
}
$select->finish();
