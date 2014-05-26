#! /usr/bin/perl
#
#  Copyright © 2013 Marc-André Pelletier <mpelletier@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

#  THIS FILE IS MANAGED BY PUPPET
#
#  Source: modules/openstack/files/replica-addusers.pl
#  From:   openstack::replica-management-service


use strict;
use DBI();

my %databases = (
      's1'  => [ "labsdb1001", 3306 ],
      's2'  => [ "labsdb1002", 3306 ],
      's3'  => [ "labsdb1003", 3308 ],
      's4'  => [ "labsdb1002", 3307 ],
      's5'  => [ "labsdb1002", 3308 ],
      's6'  => [ "labsdb1003", 3306 ],
      's7'  => [ "labsdb1003", 3307 ],
      'udb' => [ "labsdb1005", 3306 ],
);

my %dbc;


my $dbuser;
my $dbpassword;
my $mycnf = $ENV{'HOME'} . "/.my.cnf";
if(open MYCNF, "<$mycnf") {
    my $client = 0;
    while(<MYCNF>) {
        if(m/^\[client\]\s*$/) {
            $client = 1;
            next;
        }
        $client = 0 if m/^\[/;
        next unless $client;
        $dbuser = $1 if m/^\s*user\s*=\s*'(.*)'\s*$/;
        $dbpassword = $1 if m/^\s*password\s*=\s*'(.*)'\s*$/;
    }
    close MYCNF;
}
die "No credentials for connecting to databases.\n" unless defined $dbuser and defined $dbpassword;

for(;;) {

    my %dbc;
    my $dbopen = 0;
    my @projects = glob "/srv/project/*";
    my %allhomes;
    print "[enumerating homes]\n";
    foreach my $dir (glob("/srv/project/*/home/*"), glob("/srv/project/*/project/*")) {
        next if -f "$dir/replica.my.cnf";
        my @sd = stat $dir;
        next unless $#sd > -1;
        $allhomes{$dir} = $sd[4]; # uid
    }

    print "[enumerating users]\n";
    open PW, "/usr/bin/getent passwd|" or die "getent: $!\n";
    while(<PW>) {
        my ($username, undef, $uid, $gid, undef, $home, undef) = split /:/;
        next if $uid < 500;
        my @homes;
        $home =~ s/\/$//;
        $home = $1  if $home =~ m[^/data(/project/.*)$];
        foreach my $p (@projects) {
            next unless defined $allhomes{$p.$home};
            next unless $allhomes{$p.$home} == $uid;
            push @homes, $p.$home;
        }

        my $pwfile = "/var/cache/dbusers/$username";
        my $password;
        if(open PWFILE, "<$pwfile") {
            $password = <PWFILE>;
            chop $password;
            close PWFILE;
        } else {
            print "* creating credentials for $username\n";
            $password = `/usr/bin/pwgen 16 1`;
            chop $password;
            open PWFILE, ">$pwfile" or die "$pwfile: $!\n";
            print PWFILE "$password\n";
            close PWFILE;
        }

        my $t = ($uid==$gid)? 's': 'u';
        my $mysqlusr = "$t$uid";

        my $grants = "/var/cache/dbusers/$username.grants";
        unless(-f $grants) {
            unless($dbopen) {
                foreach my $dbn (keys %databases) {
                    my ($dbh, $dbp) = @{$databases{$dbn}};
                    my $c = DBI->connect("DBI:mysql:host=$dbh;port=$dbp;mysql_enable_utf8=1",
                        $dbuser, $dbpassword, {'RaiseError' => 0});
                    if(defined $c) {
                        $c->do("SET NAMES 'utf8';");
                        $dbc{$dbn} = $c;
                        print "+ connected to $dbn\n";
                    }
                }
                $dbopen = 1;
            }

            print "* grants for $username ($mysqlusr):";
            foreach my $dbn (keys %dbc) {
                print " [$dbn]";
                $dbc{$dbn}->do("grant usage on *.* to $mysqlusr\@'\%' identified by '$password';");
                $dbc{$dbn}->do("grant select, show view on `\%_p`.* to $mysqlusr\@'\%';");
                $dbc{$dbn}->do("grant show view on *.* to $mysqlusr\@'\%';");
                $dbc{$dbn}->do("grant all privileges on `${mysqlusr}__\%`.* to $mysqlusr\@'\%' with grant option;");
            }
            print "\n";
            open GRANTS, ">$grants" and close GRANTS;
        }

        next if $#homes < 0;

        foreach my $dir (@homes) {
            $pwfile = "$dir/replica.my.cnf";
            if(open MYCNF, ">$pwfile") {
                print "* creds for $username ($mysqlusr) added to $pwfile\n";
                chown $uid, $gid, $pwfile;
                chmod 0600, $pwfile;
                print MYCNF "[client]\n";
                print MYCNF "user='$mysqlusr'\n";
                print MYCNF "password='$password'\n";
                close MYCNF;
            }
        }
    }

    if($dbopen) {
        print "+ closing database connections\n";
        foreach my $db (values %dbc) {
            $db->disconnect;
        }
    }

    sleep 120;
}

