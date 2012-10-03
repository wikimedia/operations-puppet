#!/usr/bin/perl
# Query killer
# Gets rid of stuff over $x seconds long
#
# Author: Damian Zaremba <damian@damianzaremba.co.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

use warnings;
use strict;
use DBI;

# 5min query length
my $query_time = 360;

# Default pass
my $mysql_pass = 'puppet';

# Try and load the password from the user config
if( open( my $cnf, '</root/.my.cnf' ) ) {
    while ( <$cnf> ) {
        if ( /\s*pass\s*=\s*(.+)\s*/ ) {
            $mysql_pass = $1;

            # Comment stripping
            $mysql_pass =~ s/^["']//;
            $mysql_pass =~ s/["']$//;
        }
    }
    close ( $cnf );
}

# If we can connect
if( my $dbh = DBI->connect( 'DBI:mysql:mysql;host=localhost;port=3306;', 'root', $mysql_pass ) ) {
    # Get the process list
    if( my $sth = $dbh->prepare( 'SHOW PROCESSLIST' ) ) {
        $sth->execute();

        while( my $row = $sth->fetchrow_hashref() ) {
            # Ignore root, we're probably doing something important
            next if( $row->{'User'} =~ /^root$/ );

            # Check if the query time is over our limit
            if( $row->{'Time'} && $row->{'Time'} > $query_time ) {

                # Kill the query with fire
                print STDERR "Killing " . $row->{'Id'} . "(" . $row->{'Time'} . ")\n";
                my $ksth = $dbh->prepare( 'KILL ' . $dbh->quote( $row->{'Id'} ) ) ;
                $ksth->execute();
                $ksth->finish();
            }
        }

        # Tidy up
        $sth->finish();
    }

    # Disconnect and exit
    $dbh->disconnect;
    exit 0;
} else {
    print STDERR "Could not connect to MySQL\n";
    exit 1;
}
