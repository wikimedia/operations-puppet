#!/usr/bin/env perl
# We want to know if stuff is going to explode in our face
use warnings;
use strict;

# Wikipedia client
use MediaWiki::API;

# Mediawiki is too awesome to use unix time
use Date::Parse;
use Time::Local;

# We like options
use Getopt::Long;

=head1 NAME
check_wiki_user_last_edit_time.pl - A script to check the last time an account edited

=head1 OVERVIEW
This script checks the last edit time against a threashold.

=head1 AUTHOR
Damian Zaremba <damian@damianzaremba.co.uk>

=head1 LICENSE
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

# Config stuff
my %config = (
	"wiki_url" => "http://en.wikipedia.org/w/api.php",
	"wiki_user" => "DamianZaremba",
	"threashold_warn" => 900,
	"threashold_crit" => 1800,
	"help" => 0,
);

# Get the options
if( !GetOptions (\%config,
	'wiki_url=s',
	'wiki_user=s',
	'threashold_warn=i',
	'threashold_crit=i',
	'help',
) || $config{'help'} ) {
	print "Usage: " . $0 . " --wiki_url --wiki_user --threashold_warn --threashold_crit\n";
	print "wiki_url - URL to the wiki API endpoint, default is http://en.wikipedia.org/w/api.php\n";
	print "wiki_user - Username to check, default is DamianZaremba\n";
	print "threashold_warn - Warning threashold in seconds, default is 900\n";
	print "threashold_crit - Critical threashold in seconds, default is 1800\n";
	exit( 3 );
}

my $wiki = MediaWiki::API->new();
$wiki->{'config'}{'api_url'} = $config{'wiki_url'};

my $userinfo = $wiki->api({
	action => 'query',
	list => 'usercontribs',
	ucuser => $config{'wiki_user'},
	'uclimit' => 1,
});

my $edit = $userinfo->{'query'}->{'usercontribs'}[0];
if( ! $edit ) {
	my $error = $wiki->{'error'}->{'details'}; chomp( $error );
	print "[Unknown] Could not get the user contribs: " . $error . "\n";
	exit( 3 );
}

my $editUNIXTime = str2time( $edit->{'timestamp'} );
my $time = time();
my $difference = $time-$editUNIXTime;

if( $difference > $config{'threashold_crit'} ) {
	print "[Critical] Last edit time for " . $config{'wiki_user'} . " was " . $edit->{'timestamp'} . "\n";
	exit( 2 );
}

if( $difference > $config{'threashold_warn'} ) {
	print "[Warning] Last edit time for " . $config{'wiki_user'} . " was " . $edit->{'timestamp'} . "\n";
	exit( 1 );
}

print "[OK] Last edit time for " . $config{'wiki_user'} . " was " . $edit->{'timestamp'} . "\n";
exit( 0 );
