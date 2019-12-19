#!/usr/bin/env perl

=pod

=head1 NAME

logspam - summarize exceptions from production logs

=head1 USAGE

    # Just get a list of recent exceptions:
    logspam

    # Monitor logspam output every 10 seconds, sorted:
    watch -n 10 sh -c "./bin/logspam | sort -nr"

    # Like the above, but filter out Parsoid spam:
    watch -n 10 sh -c "./bin/logspam | grep -v parsoid | sort -nr"

    # A quick shorthand for invoking watch(1):
    logspam-watch

=head1 DESCRIPTION

This deduplicates exceptions from exception.log, error.log, and fatal.log and
prints them with a leading count of their occurrence and a snippet of the
stacktrace.  In the interests of concision, it shortens exception names by
removing any trailing "Exception" and condenses file paths.

In practice, you may want the logspam-watch wrapper.

This is hacky and contains many assumptions, but has proven useful when
watching for breakage during deploys.

=cut

use warnings;
use strict;
use 5.10.0;
use utf8;
use open qw(:std :utf8);

use List::Util qw(min max);

my $terminal_width = `tput cols`;
chomp $terminal_width;

# Default to /srv/mw-log, use MW_LOG_DIRECTORY if available from
# environment:
my $mw_log_dir = '/srv/mw-log';
if (defined $ENV{MW_LOG_DIRECTORY}) {
  $mw_log_dir = $ENV{MW_LOG_DIRECTORY};
}

# Be lazy and shell out to tail:
my $log_path_str = join ' ', (
  "${mw_log_dir}/exception.log",
  "${mw_log_dir}/error.log",
  "${mw_log_dir}/fatal.log",
);
my $loglines =  `tail -n 3000 -q $log_path_str`;

# Treat the datestamped log line as a separator between records - we're
# interested in how often the stack trace appears
my @errors = split m{

  ^           # Start of datestamped log line
    [\d-]{10} # Datestamp
    .*        # Remainder of line
  $           # EOL

}mx, $loglines;

my %consolidate_patterns = (
  '[mem size]' => qr/Allowed memory size of/,
  '[max time]' => qr/Maximum execution time of 180 seconds exceeded/,
);

# A pattern for extracting exception names and the invariant stack traces from
# errors looking like so:
# [Exception WMFTimeoutException] (/srv/mediawiki/wmf-config/set-time-limit.php:39) the execution time limit of 60 seconds was exceeded
#   #0 /srv/mediawiki/php-1.35.0-wmf.4/includes/parser/Preprocessor_Hash.php(689): {closure}(integer)
#   #1 /srv/mediawiki/php-1.35.0-wmf.4/includes/parser/Parser.php(3125): Preprocessor_Hash->preprocessToObj(string, integer)
#   ...
my $exception_pat = qr{

  ^                         # Start of error
    \[Exception [ ] (.*?)\] # Yank out the class of our exception
    (.*?)                   # Stack trace
  $                         # End of error

}mx;

# Count times each stacktrace appears:
my %unique_errors;
my $max_exception_len = 0;
foreach (@errors) {
  next unless $_ =~ $exception_pat;
  my $exception_class = $1;
  my $stack_trace = shorten($2);

  # Condense some common errors:
  for my $key (keys %consolidate_patterns) {
    if ($stack_trace =~ $consolidate_patterns{$key}) {
      $exception_class = $key;
      $stack_trace = $consolidate_patterns{$key};
    }
  }

  # Drop the namespace of the exception class and chop off the typical
  # trailing "Exception":
  $exception_class =~ s{[a-z] [a-z]+ \\}{}xgi;
  $exception_class =~ s{Exception$}{};

  # Retain this for display use:
  $max_exception_len = max(length $exception_class, $max_exception_len);

  my $unique_error_msg = "$exception_class\t$stack_trace";
  $unique_errors{$unique_error_msg}++;
}

my $display_width = $terminal_width - ($max_exception_len + 16);

foreach (keys %unique_errors) {
  my ($exception, $trace) = split "\t";

  my $count = $unique_errors{$_};
  my $display_exception = sprintf("% ${max_exception_len}s", $exception, $_);
  my $display_trace = substr($trace, 0, $display_width);

  say join "\t", ($count, $display_exception, $display_trace);
}

=head1 SUBROUTINES

=over

=item shorten($stack_trace)

Condense and format traces matching some common patterns.

=cut

sub shorten {
  my ($stack_trace) = @_;

  my $mw_root = '/srv/mediawiki/';
  my $parsoid_root = '/srv/deployment/parsoid/deploy-cache/revs/';

  # Strip trailing / leading whitespace:
  $stack_trace =~ s/^ \s+ | \s+ $//gx;

  if ( $stack_trace =~ m{^ \( $mw_root php-.*(wmf[.].*?)/ (.*?) \) (.*) $}x ) {
    my ($version, $path, $trace) = ($1, $2, $3);
    $path = condense_path($path);
    $stack_trace = "$version $path $trace";
  }

  if ( $stack_trace =~ m{^ \( $parsoid_root ([a-z0-9]{6}) .*? / (.*?) \) (.*) $}x) {
    my ($rev, $path, $trace) = ($1, $2, $3);
    $path = condense_path($path);
    $stack_trace = "parsoid:$rev $path $trace";
  }

  return $stack_trace;
}

=item condense_path($path)

Condense a typical file path by reducing to the first letter of each leading
particle, like:

    includes/foo/bar/baz.php

Becomes:

    i/f/b/baz.php

=cut

sub condense_path {
  my ($path) = @_;
  $path =~ s!([a-z]) [a-z.]+ /!$1/!xgi;
  return $path;
}

=back

=cut
