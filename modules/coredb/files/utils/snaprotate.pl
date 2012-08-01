#!/usr/bin/perl -w
# vim:ai:filetype=perl:sta:sw=4:et:

use strict;
use Getopt::Long;
use Pod::Usage;

Getopt::Long::Configure('gnu_getopt',
                        'prefix_pattern=(--|-)');

my $DEBUG=0;

# Declarations
#
my $TRESHOLD=90;
my $SNAPCOUNT=2;

my ($ACTION, $VOLGRP, $SRCLV, $SNSIZE)=();
my ($SHOWALL, $SNAME, $MAILTO, $OPTIONS, $HELP)=();
my @snaps=();
my $outstr;
my @tmparr;

# main
GetOptions ('option|o' => \$OPTIONS,
            'action|a=s' => \$ACTION,
            'all|A' => \$SHOWALL,
            'volgroup|V=s' => \$VOLGRP,
            'sourcelv|s=s' => \$SRCLV,
            'mailto|m=s' => \$MAILTO,
            'snapname|n=s' => \$SNAME,
            'size|L=s' => \$SNSIZE,
            'treshold|t=i' => \$TRESHOLD,
            'snapcount|c=i' => \$SNAPCOUNT,
            'help|h' => \$HELP)
    or pod2usage(-verbose => 0, -exitval => 2);

pod2usage(-verbose => 1) if ($OPTIONS);
pod2usage(-verbose => 2) if ($HELP);


if ( not defined $ACTION or ($ACTION !~ /^s(wap)?$/ and $ACTION !~ /^m(ail)?$/
    and $ACTION !~ /^r(eport)?$/)) {
    print STDERR "Error: missing or invalid action type.\n";
    pod2usage(-verbose => 0, -exitval => 2);
}
elsif (not defined $VOLGRP or not defined $SRCLV or (not defined $SNSIZE and
    $ACTION =~ /^s/)) {
    print STDERR "Error: missing mandatory option.\n";
    pod2usage(-verbose => 0, -exitval => 2);
}
elsif ($ACTION =~ /^s/ and $SNSIZE !~ /^\d+[kmgt]?$/i) {
    print STDERR "Error: Invalid size value.\n";
    pod2usage(-verbose => 0, -exitval => 2);
}
elsif ($ACTION =~ /^s/ and $SNAPCOUNT < 1) {
    print STDERR "Error: use a positive integer for \"snapcount\".\n";
    pod2usage(-verbose => 0, -exitval => 2);
}
elsif ($ACTION =~ /^m/ and $MAILTO !~ /^[\w\.-]+(@[\w-]+(\.[\w-]+)*)?$/) {
    print STDERR "Error: Missing or invalid mail address.\n";
    pod2usage(-verbose => 0, -exitval => 2);
}

# More declarations
my @lvscmd=("/sbin/lvs", "--noheadings", "--options",
    "lv_name,lv_attr,vg_name,origin,snap_percent");
my @lvcrt=("/sbin/lvcreate", "--snapshot", "--size", $SNSIZE, "--name", 
    "__FOO__", "--permission", "rw", "/dev/$VOLGRP/$SRCLV");
my @lvrm=("/sbin/lvremove", "-f", "__FOO__");
my @dfcmd=("/bin/df", "-k");
my @lsofcmd=("/usr/bin/lsof","+D");
my $mailprog="/usr/bin/Mail";

#get lvs info
$outstr=&Backticks(@lvscmd);
chomp $outstr;
@tmparr=split("\n",$outstr);
foreach my $lvsline (@tmparr) {
    my @lvarr=split(" ", $lvsline);
    next if (scalar @lvarr != 5 or $lvarr[2] ne $VOLGRP or $lvarr[3] ne $SRCLV);
    push @snaps, \@lvarr;
}

if ($ACTION =~ /^s/) {
    while (scalar(@snaps) >= $SNAPCOUNT)  {
        # Delete oldest
        my $oldest="";
        my $percent=0;
        foreach my $lvline (@snaps) {
            if ($oldest eq "") {
                $oldest=$lvline->[0];
                $percent=$lvline->[4];
            }
            else {
                if ($lvline->[4] > $percent) {
                    $oldest=$lvline->[0];
                    $percent=$lvline->[4];
                }
                else {
                }
            }
        }
        # remove the entry from from @snaps
        @tmparr=();
        foreach my $lvline (@snaps) {
            push @tmparr, $lvline if ($lvline->[0] ne $oldest);
        }
        @snaps=@tmparr;
        # Check if the snapshot is mounted
        my @filesys=&Unfold(@dfcmd);
        foreach my $dfline(@filesys) {
            my @dfres=split(" ", $dfline, 6);
            next if ($dfres[0] ne "/dev/mapper/$VOLGRP-$oldest");
            my @pids;
            my $lsofoutp=&Backticks(@lsofcmd, $dfres[5]);
            foreach my $line (split "\n", $lsofoutp) {
                chomp $line;
                next if ($line =~ /^COMMAND/);
                my @elems=split(" ",$line);
                unshift @pids, $elems[1];
            }
            # kill processes on the mounted snapshot
            my $dummy=&Backticks("/bin/kill","-KILL",@pids) if (scalar(@pids) > 0);
            # umount the snapshot
            $dummy=&Backticks("/bin/umount",$dfres[5]);
            die "Could not umount snapshot \"$oldest\".\n" if ($?);
        }
        $lvrm[2]="/dev/$VOLGRP/$oldest";
        # remove the snapshot
        my $dummy=&Backticks(@lvrm);
        die "Could not remove old snapshot \"$oldest\".\n" if ($?);
    }
    if (not defined $SNAME or $SNAME eq "") {
        my ($min,$hour,$day,$mon);
        ($_,$min,$hour,$day,$mon,$_,$_,$_,$_)=localtime();
        $mon=sprintf("%02d",++$mon);
        $day=sprintf("%02d",$day);
        $hour=sprintf("%02d",$hour);
        $min=sprintf("%02d",$min);
        $SNAME="snap$mon$day$hour$min";
    }
    $lvcrt[5]=$SNAME;
    my $dummy=&Backticks(@lvcrt);
    die "Could not create new snapshot.\n" if ($?);
    exit 0;
}
else {
    #ACTION eq mail|report
    my $mailbody="";
    foreach my $snap (@snaps) {
        if ($SHOWALL) {
            $mailbody .= "Snapshot percentage for $snap->[0] is $snap->[4]\%\n";
        }
        if ($snap->[1] =~ /^S/) {
            $mailbody .= "ERROR: snapshot $snap->[0] is broken!\n";
        }
        elsif ($snap->[4] >= $TRESHOLD) {
            $mailbody .= "WARNING: snapshot $snap->[0] is filled " . 
                "above treshold ($snap->[4]\%)\n";
        }
    }
    if ($mailbody ne "") {
        if ($ACTION =~ /^m/) {
            die "No mailaddress specified\n" if (not defined $MAILTO);
            my $pid=undef;
            my @mailcmd=($mailprog,"-s","Snapshot report for /dev/$VOLGRP/$SRCLV",
                $MAILTO);
            if ($pid = open (CHILD,"|-")) {
                print CHILD $mailbody;
            }
            else {
                die "Cannot fork.\n" unless defined $pid;
                exec @mailcmd;
            }
        }
        else {
            print STDERR $mailbody;
        }
    }
}

# Start of subs
sub Unfold {
    my $result=&Backticks(@_);
    chomp $result;
    $result=~s/\n\s+/ /g;
    my @res=split("\n",$result);
    return @res;
}

sub Backticks {
    my @arr=@_;
    my ($result,$pid);
    if ($pid = open (CHILD,"-|")) {
        local $/;
        return <CHILD>;
    }
    else {
        if ( ! defined $pid ) {
            die "Cannot fork.\n";
        }
        if ( ! -x $arr[0] ) {
            die "Cannot execute $arr[0]\n";
        }
        print STDERR "executing ".join(" ",@arr)."\n" if ($DEBUG);
        exec @arr;
    }
}


__END__

=head1 NAME

snaprotate.pl - Use rotating snapshots as a backup means.

=head1 SYNOPSIS

B<snaprotate.pl> B<-a>|B<--action> I<s[wap] | m[ail] | r[eport]>
[B<-A>|B<--all>] B<-V>|B<--volgroup> I<vg>
B<-s>|B<--sourcelv> I<lv> [B<-L>|B<--size> I<snapsize>] 
[B<-n>|B<--snapname> I<snapvol>] [B<-m>|B<--mailto> I<user@fqdn>] 
[B<-t>|B<--treshold> I<value>] [B<-c>|B<--snapcount> I<value>] 

B<snaprotate.pl> B<-h>|B<--help>

B<snaprotate.pl> B<-o>|B<--options>

=head1 DESCRIPTION

This script will either rotate between snapshots of a logical volume or
report if a snapshot volume is used more than a treshold value (default 90%).
When rotating, the snapshot volume with most usage is deleted and a new one
is created.

=head1 OPTIONS

=over 4

=item B<-a, --action> I<s[wap] | m[ail] | r[eport]>

Mandatory option. The I<swap> option will delete the oldest snapshot if
all snapshots are used (or more oldest if more snapshots are used).
WARNING: if a snapshot to be deleted is mounted, it will first be unmounted.
If the filesystem is busy, all processed on the filesystem are killed with a 
SIGKILL.

The <report> and I<mail> options check if a snapshot is used more than
the treshold value or if a snapshot became invalid. I<report> prints the
message to stderr and I<mail> sends the message to a mail address.

=item B<-A, --all>

Show usage info for all snapshots. This option is only used with the I<mail>
and I<report> action types.

=item B<-V, --volgroup> I<vg>

The volume group that the logical volumes are members of. Mandatory option.

=item B<-s, --sourcelv> I<lv>

The logical volume that is snapped. Also mandatory.

=item B<-n, --snapname> I<snapvol>

Use this name as the name for the newly created snapshot (optional).

=item B<-L, --size> I<snapsize>

The size of the logical volume (use a suffix of K, M or G for Kibi, Mebi or
Gibibytes). This option is mandatory for the I<swap> action, else ignored.

=item B<-m, --mailto> I<user@fqdn>

The user to where a warning of the snap utilization is mailed to. This option
is ignored unless the I<mail> action is used but is mandatory when it is.

=item B<-t, --treshold> I<value>

The percentage of snap usage where the report option will generate an warning.
The default value is 90. This value is only used by the I<mail> and 
I<report> actions.

=item B<-c, --snapcount> I<value> 

The number of snapshots to cycle through. When fewer snapshots are available,
nothing is deleted. If more than this number are available, the excess plus one
more are deleted. The default number is 2. This option is only used by the 
I<swap> action.

=item B<-o, --options>

Print the list of command line options.

=item B<-h, --help>

Show the manpage.

=head1 AUTHOR

Rob S. Wolfram E<lt>propdf@hamal.nlE<gt>

=head1 LICENSE

This program is licensed according to the GNU General Public License
(GPL) Version 2, or at your discretion, any later version. A copy of the
license text can be obtained from E<lt>http://www.gnu.org/licenses/gpl.htmlE<gt>
or by mailing the author. In short it means that there are no restrictions on
its use, but distributing the program or derivative works is only allowed
according to the terms of the GPL.

=cut

