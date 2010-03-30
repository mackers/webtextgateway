package IncomingFormat;

=head1 NAME

IncomingFormat - Process information from HTTPSMS

=head1 SYNOPSIS

use B<IncomingFormat>;

my $responses = B<IncomingFormat::processIncoming>(input);
my @responses = @$responses;

=head1 DESCRIPTION

This module can be used to process information from the HTTPSMS system.
The server will output receipts and messages separated by the #
character; this module's B<processIncoming> subroutine will separate
each receipt and return a reference to an array of array references,
each representing the fields of a response.

This can be given to B<determineType> to print the details to the
standard output.

=cut

use strict;
use 5.6.8;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;

$VERSION = '1.0';

my $errstr;

sub errstr {
    if (!defined($errstr)) {
        return "Internal library (IncomingFormat) error. Called from code";
    }
    return $errstr;
}

=head1 PROCESS INCOMING

    my $incoming = '2#1128173:447111111111:447000000000:1:0:1180019698:AF31 C0D:#-1:447111111112:447000000003:1:1180019700::48656C6C6F';
    my $responses = IncomingFormat::processIncoming($incoming);

Takes as input a response string received from the server. Returns an
array reference. Each reference in the returned array is to an array of
the fields of the message.

=cut

sub processIncoming {
    my $input = shift;
    my @to_return;

    my @receipts = split(/#/, $input);

    # First received part is a count, which we can ignore
    shift @receipts;

    my $receipt;
    foreach $receipt (@receipts) {
        my @field = split(/:/, $receipt);
      #  my $hashreceipt = { "ID" => $field[0], "destination" => $field[1], "source" => $field[2], "status" => $field[3], "errorCode" => $field[4], "deliveryTime" => $field[5], "userReference" => $field[6], "message" => $field[7] };
        push(@to_return, \@field);
    }

    return \@to_return;
}

=head1 DETERMINE TYPE

    IncomingFormat::determineType($responses);

This examines each element of the response given by processIncoming,
determines whether each response is a delivery receipt or an incoming
SMS, and calls the appropriate print routine to display the information.
Takes as input the reference returned by processIncoming.

=cut

sub determineType {
    my $incoming = shift;
    if (!$incoming) {
        return;
    }
    my @incoming = @$incoming;

    foreach my $message (@incoming) {
        my ($type) = @$message;

        if ($type eq '-1') {
            incomingSMS(@$message);
        } else {
            deliveryReceipt(@$message);
        }
        print "\n";
    }
}

=head1 DELIVERY RECEIPT

    IncomingFormat::deliveryReceipt(@fields);

Given the fields of a delivery receipt, prints out field labels and
data in a simple, line-based format. Each line printed will have a key
name, a colon, a space and a field, e.g.

    MSGID: 1128173
    SOURCE: 447111111111
    DESTINATION: 447000000000
    STATUS: 1
    ERRORCODE: 0
    DATETIME: 1180019698
    USERREF: AF31C0D

=cut

sub deliveryReceipt {
    my ($msgid, $source, $destination, $status, $errorcode, $datetime, $userref, @message) = @_;

    print "MSGID: $msgid\n";
    print "SOURCE: $source\n";
    print "DESTINATION: $destination\n";
    print "STATUS: $status\n";
    print "ERRORCODE: $errorcode\n";
    print "DATETIME: $datetime\n";
    print "USERREF: $userref\n";
}

=head1 INCOMING SMS

    IncomingFormat::incomingSMS(@fields);

Given the fields of an incoming SMS, prints out field labels and
data in a simple, line-based format. Each line printed will have a key
name, a colon, a space and a field, e.g.

    SOURCE: 447111111112
    DESTINATION: 447000000003
    DCS: 1
    DATETIME: 1180019700
    UDH: 
    MESSAGE: 48656C6C6F

=cut

sub incomingSMS {
    my ($minusone, $source, $destination, $dcs, $errorcode, $datetime, $udh, $message) = @_;

    print "SOURCE: $source\n";
    print "DESTINATION: $destination\n";
    print "DCS: $dcs\n";
    print "DATETIME: $datetime\n";
    print "UDH: $udh\n";
    print "MESSAGE: ";
    print (pack ("H*", $message)) . "\n";
}

1;
__END__

=head1 COPYRIGHT

Copyright 2007 CardBoardFish http://www.cardboardfish.com/

=cut
