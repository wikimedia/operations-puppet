#! /usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

my $dbuser;
my $dbpwd;
open INI, "<replica.my.cnf" or die "replica.my.cnf: $!\n";
while(<INI>) {
    $dbuser = $1 if m/^user='(.*)'$/;
    $dbpwd  = $1 if m/^password='(.*)'$/;
}
close INI;

my $db = DBI->connect("DBI:mysql:database=toollabs_p;host=tools.labsdb", $dbuser, $dbpwd);

die "Unable to connect to database\n" unless defined $db;

my %users;
my %tools;

my $st = $db->prepare("select * from users");
$st->execute();
while(my $row = $st->fetchrow_hashref()) {
    $users{$row->{name}} = $row;
}
$st = $db->prepare("select * from tools");
$st->execute();
while(my $row = $st->fetchrow_hashref()) {
    $tools{$row->{name}} = $row;
}

my %intools;
my $pmembers = (getgrnam 'project-tools')[3];
foreach my $uname (split /\s+/, $pmembers) {
    $intools{$uname} = 1;
}

while(my @pw = getpwent) {
    if($pw[0] =~ m/^tools\.(.+)$/) {
        my $tool = $1;
        next unless -X $pw[7];
        $tools{$tool} = { insert => 1 } unless defined $tools{$tool};
        $tools{$tool}->{id} = $pw[2];
        $tools{$tool}->{home} = $pw[7];
        $tools{$tool}->{maintainers} = (getgrnam "tools.$tool")[3];
        $tools{$tool}->{active} = 1;
    } else {
        next unless $pw[3] == 500;
        next unless $pw[8] eq '/bin/bash';
        next unless defined $intools{$pw[0]};
        $users{$pw[0]} = { insert => 1 } unless defined $users{$pw[0]};
        $users{$pw[0]}->{id} = $pw[2];
        $users{$pw[0]}->{wikitech} = ucfirst $pw[6];
        $users{$pw[0]}->{home} = $pw[7];
        $users{$pw[0]}->{active} = 1;
    }
}

sub insertupdate($$$$) {
    my($table, $name, $cols, $hash) = @_;

    my %cols;
    foreach my $cn (@$cols) {
        next unless defined $hash->{$cn};
        $cols{$cn} = $db->quote($hash->{$cn});
    }
    my $stmt;
    if($hash->{insert}) {
        $stmt = "INSERT INTO $table (name, "
              . join(', ', keys %cols)
              . ") VALUES ("
              . $db->quote($name)
              . ", "
              . join(', ', values %cols)
              . ")";
    } else {
        $stmt = "UPDATE $table SET";
        foreach my $cn (keys %cols) {
            $stmt .= ", $cn=$cols{$cn}";
        }
        $stmt =~ s/ SET,/ SET/;
        $stmt .= " WHERE name=" . $db->quote($name);
    }
    return $db->do($stmt);
}

my @toolcols = ('id', 'home', 'description', 'toolinfo', 'maintainers', 'updated');
my @usercols = ('id', 'wikitech', 'home');
my $now = time;
foreach my $tool (keys %tools) {
    unless($tools{$tool}->{active}) {
        $db->do("delete from tools where name='$tool'");
        next;
    }
    my $lastupdate = $tools{$tool}->{updated} // 0;
    $tools{$tool}->{home} =~ s/\/+$//;
    if(($now-$lastupdate) >= 300) {
        $tools{$tool}->{description} = '';
        $tools{$tool}->{toolinfo} = '';
        if(open DF, "<", $tools{$tool}->{home} . "/.description") {
            my @df = <DF>;
            $tools{$tool}->{description} = join ' ', @df;
            close DF;
        }
        if(open DF, "<", $tools{$tool}->{home} . "/toolinfo.json" or
           open DF, "<", $tools{$tool}->{home} . "/public_html/toolinfo.json") {
           my @ti = <DF>;
           $tools{$tool}->{toolinfo} = join ' ', @ti;
           close DF;
        }
        $tools{$tool}->{updated} = $now;
    }
    insertupdate('tools', $tool, \@toolcols, $tools{$tool});
}
foreach my $user (keys %users) {
    unless($users{$user}->{active}) {
        $db->do("delete from tools where name='$user'");
        next;
    }
    insertupdate('users', $user, \@usercols, $users{$user});
}

