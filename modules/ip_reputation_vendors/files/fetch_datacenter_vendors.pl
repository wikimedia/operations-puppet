#!/usr/bin/env perl
# SPDX-License-Identifier: Apache-2.0
use strict;
use warnings;

use Getopt::Long;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use JSON;
use LWP::UserAgent;
use MaxMind::DB::Writer::Tree;
use Pod::Usage;

# Spur.us endpoint
my $url = "https://feeds.spur.us/v2/dch/latest.json.gz";

# Options
GetOptions( 'tmpfile=s' => \my $tmpfile
          , 'output=s' => \my $output
          , 'help|?' => \my $help
          ) or pod2usage(2);
pod2usage(1) if $help;

# Fail and print usage if options is not set.
defined $tmpfile || pod2usage(1);
defined $output || pod2usage(1);
defined $ENV{SPUR_TOKEN} || die "Please add access token to environment variable SPUR_TOKEN\n";

# Setup mmdb as a GeoLite2-ASN database to allow us to more
# easily work on the data with other Maxmind libraries.
my %network_type = (
    autonomous_system_organization => 'utf8_string',
);

my $tree = MaxMind::DB::Writer::Tree->new(
    ip_version            => 6,
    record_size           => 24,
    database_type         => 'GeoLite2-ASN',
    languages             => ['en'],
    description           => { en => 'WMF - Known datacenters database' },
    map_key_type_callback => sub { $network_type{ $_[0] } },
);

# Load proxy settings.
my $ua = LWP::UserAgent->new(timeout => 30);
$ua->env_proxy;

# Setup request with authentication token and user-agent (because we're nice like that).
my $req = HTTP::Request->new(GET => $url);
$req->header('token' => $ENV{SPUR_TOKEN});
$req->header('user-agent' => 'Wikimedia Foundation - noc@wikimedia.org');

# Fetch and gunzip data feed.
my $resp = $ua->request($req, $tmpfile . ".gz");

die "Spur.us feed download failed with: " , $resp->code , " " , $resp->message, "\n" unless $resp->is_success;

print "Downloaded spur.us feed: HTTP" , $resp->code , "\n";
my $compressed = $tmpfile . ".gz";

# Check the file size of the downloaded .gz file. This should not be more than
# a few hundred megabytes.
open my $gz_fh, '<:raw', $compressed or die "Cannot open $compressed: $!";
my $size_bytes;

# Read the last 2 bytes, which stores the file size, if the archive is less than 2GB.
seek($gz_fh, -4, 2) or die "Cannot seek in $compressed: $!";
read($gz_fh, $size_bytes, 4) or die "Cannot read from $compressed: $!";
my $uncompressed_size = unpack('V', $size_bytes) / 1024 / 1024;
die "Downloaded data feed larger than expected, will not uncompress" unless $uncompressed_size < 1024;
close $gz_fh;

gunzip $compressed => $tmpfile
or die "gunzip failed: $GunzipError\n";


# Read data feed line by line, and parse each line as a separate
# JSON document.
open my $info, '<', $tmpfile or die "Could not open $tmpfile: $!";
my $count = 0;
while( my $line = <$info>)  {
    my $networks;

    # Wrap in eval to catch errors in JSON decoding.
    eval {
        $networks = decode_json $line;
    };

    # $@ contains error state from decode_json, if decoding fails.
    if ($@) {
        print "Unable to parse feed, error on line ", $count +1, "\n";
        print "JSON data was: " , $line;
        die "Unable to parse JSON input: ", $line, "\n";
    }

    # Basic sanitization of the organization name.
    # 1) Lower case the name.
    # 2) Remove any trailing periods.
    # 3) Replace commas with space.
    my $organization = lc $networks->{'organization'};
    $organization =~ s/.$//;
    $organization =~ s/, / /;
    $tree->insert_network(
        $networks->{'network'},
        {

            autonomous_system_organization => $organization,
        },
    );
    $count += 1;
}
close $info;

# Write mmdb.
open my $fh, '>:raw', $output;
$tree->write_tree($fh);
print "Wrote new mmdb: " , $output , "\n";
print $count , " networks in database.\n";

# Remove temporary files.
my $deleted = unlink $compressed, $tmpfile;
die "Failed to delete temporary files: " , $! , "\n" unless $deleted == 2;


# Help information for pod2usage.

__END__

=head1 NAME

spur-mmdb - Convert Spur.us datacenter feed to mmdb

=head1 SYNOPSIS

spur-mmdb.pl [options]

 Options:
   -help            brief help message
   -output          output file, mmdb format
   -tmpfile         Temporary download location for Spur.us JSON file

=cut
