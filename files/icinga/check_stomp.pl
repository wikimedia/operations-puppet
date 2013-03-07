#!/usr/bin/perl -w

# Simple check to see if we can write and then read back from an ActiveMQ server
#
# ex. check_stomp.pl erzurumi.pmtpa.wmnet 3 monitoring

use strict;
use Net::Stomp;

my $host    = $ARGV[0];
my $nummsgs = $ARGV[1];
my $queue   = $ARGV[2];

my $stomp = Net::Stomp->new( { hostname => $host, port => '61613' } );

$stomp->connect();

for ( my $i = 0 ; $i < $nummsgs ; $i++ ) {
    $stomp->send(
        {
            destination => "/queue/$queue",
            body        => "$queue$i",
            persistent  => 'true'
        }
    );
}

$stomp->subscribe(
    {
        destination             => "/queue/$queue",
        'ack'                   => 'client',
        'activemq.prefetchSize' => 1
    }
);

my $count = 0;
for ( my $i = 0 ; $i < $nummsgs ; $i++ ) {
    my $frame = $stomp->receive_frame;
    my $body  = $frame->body;
    if ( $body eq "$queue$i" ) {
        $count++;
    }
    $stomp->ack( { frame => $frame } );
}

$stomp->disconnect();

print "Produced: $nummsgs Consumed $count\n";

if ( $count == $nummsgs ) {
    exit(0);
}
elsif ( ( $count != $nummsgs ) && ( $count != 0 ) ) {
    exit(1);
}
elsif ( $count == 0 ) {
    exit(2);
}

