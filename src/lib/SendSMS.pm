package SendSMS;

=head1 NAME

SendSMS - A module for interacting with HTTPSMS servers

=head1 SYNOPSIS

Basic usage:

=over

use B<SendSMS>;

B<SendSMS::initialise>(username, password);

my @responses = B<SendSMS::sendSMS>(destination, source, message);

=back

See later for advanced usage.

=head1 DESCRIPTION

This module is designed to aid the creation of applications which
require the ability to send SMS messages. A valid username and
password are required for the use of this module. Once used to
initialise the module, the username and password will be used in
all communications with the server.

=cut

use strict;
use 5.6.8;

use vars qw($VERSION @ISA @EXPORT);

use Net::HTTP;
use SMS;

require Exporter;

$VERSION = '1.0';

my $errstr;
my $errcode;

sub errstr {
    if (!defined($errstr)) {
        return "No (SendSMS) error. Called from code";
    }
    return $errstr;
}

my $BATCHSIZE = 10;

my $username = "";
my $password = "";
my $clientType = "";

=head1 INITIALISATION

To initialise the module, simply call the initialise subroutine with your username and password:

    SendSMS::initialise("myUsername", "mypass");

You can also specify a client type, indicating the kind of application
for which the module is being used:

    SendSMS::initialise("myUsername", "mypass", "H");

In this case, "H" signfies an HTTP-based client. This is the default
setting.

It is best to check that no problems have been detected during this
step, using the standard "or B<die>" approach:

    SendSMS::initialise("myUsername", "mypass")
      or die (SendSMS->errstr);

=cut

sub initialise {
    my $argc = @_;
    if ($argc == 2) {
        my ($un, $passwd) = @_;
        return SendSMS::initialise($un, $passwd, "H");
    } elsif ($argc == 3) {
        my ($un, $passwd, $type) = @_;

        if (($un =~ m/^.+$/) && ($passwd =~ m/^.+$/)) {
           if ($type =~ /^[HSDM]$/) {
               ($username, $password, $clientType) = ($un,$passwd,$type);
               return 1;
           } else {
               $errstr = qq{Client type must be one of "H", "S", "D" or "M", error};
               return;
           }
        } else {
            $errstr = "Username and password must not be empty, error";
            return;
        }
    }
}

=head1 BASIC MESSAGE SENDING

Once the module has been initialised, messages can be sent like this:

    SendSMS::sendSMS("447123456789", "MyName",
        "This is the message I want to send.")
        or die (SendSMS->errstr);

The phone number should be given in international format, without the
leading +.

There are numerous checks to ensure you are trying to do something
which is sensible and allowed. The first parameter can be a string
representing a phone number, or a list of phone numbers separated with
commas:

    SendSMS::sendSMS("447123456789,447912345678", "MyName",
        ...

Again, the phone numbers should be in international format, without
the leading + sign.

The subroutine returns an array of message identifiers. If a destination
you have supplied is invalid, the corresponding identifier will be
-15; in most cases it will be a large positive number.

A recommended session, therefore, might go like this:

    use SendSMS;

    SendSMS::initialise("username", "password");
    
    my @replies;
    @replies = SendSMS::sendSMS("447123456789",
        "SMS_Service","This is to let you know this is working.")
        or die (SendSMS->errstr);
    
These three parameters are all normal Perl scalars, and as such can be
generated or read in from some data source.

=head1 ADVANCED MESSAGE SENDING

The handling of messages internally is done with SMS objects. In order
to provide the maximum of flexibility, these objects are also available
to you, via the SMS module:

    use SMS;

    my $sms = SMS->new("447123456789","SMS_Service",
        "Test message") or die (SMS->errstr);
    $sms->setDU("1234567890") or die ($sms->errstr);
    my @replies = SendSMS::sendSMS($sms)
        or die (SendSMS->errstr);

More details of this are available in the documentation for the
L<SMS> module.

=cut

sub sendSMS {
    $errstr = "Could not connect to server. Called from code";
    my $s = Net::HTTP->new(Host => "sms1.cardboardfish.com:9001") or return;
    undef $errstr;

    my @replies;

    # These two lines should enable persistent connections:
    $s->http_version(1.1);
    $s->keep_alive("TRUE");

    # A bit of Perl trickery to find out how the sub was called
    my $argc = @_;
    if ($argc == 3) {
        my ($da, $sa, $m) = @_;

        # Split the list of numbers at the commas
        my @das = split(/,/, $da);

        # Find out how many numbers we're dealing with
        my $dests = @das;

        # Calculate the necessary number of batches
        my $batches = int($dests / $BATCHSIZE) + 1;
        my $base = 0;

        # Loop to send each batch
        while ($batches > 0) {
            my $bsize;

            # If this is the last batch
            if ($batches == 1) {

                # How many destinations are left?
                $bsize = $dests % $BATCHSIZE;
            } else {

                # If not, it'll be a full batch
                $bsize = $BATCHSIZE;
            }
            my $top = $base + ($bsize - 1);

            # Prepare a batch
            my @batch = @das[$base .. $top];
            my $batchda = join(",", @batch);
            my $sm = SMS->new($batchda, $sa, $m) or
                $errstr = SMS->errstr,
                return;

            # Send this batch and get the replies
            my @batchreplies = sendSMS($sm);
            if (@batchreplies == 0) {
                if ($errcode == -15) {
                    foreach (@batch) {
                        push (@batchreplies, -15);
                    }
                } else {
                    return;
                }
            }
            my $count = 0;
            my $brep;

            # Deal with the retrying of messages where necessary
            foreach $brep (@batchreplies) {
                if ($brep == -20) { $count++; }
            }
            if ($count == 0) {
                @replies[$base .. $top] = @batchreplies;
            } else {
                my @to_retry;
                my $i;
                for ($i = 0; $i < $bsize; $i++) {
                    if ($batchreplies[$i] == -20) {
                        push(@to_retry, $batch[$i]);
                    }
                }
                my $rda = join(",", @to_retry);
                $sm->setDA($rda) or $errstr = SMS->errstr, return;
                my @retry_replies = sendSMS($sm) or return;
                for($i = 0; $i < $bsize; $i++) {
                    if ($batchreplies[$i] == -20) {
                        $batchreplies[$i] = shift @retry_replies;
                    }
                }
                @replies[$base .. $top] = @batchreplies;
            }
            $base += $BATCHSIZE;
            $batches--;
        }
        return @replies;
    } elsif ($argc == 1) {

        # If we received an SMS object
        my $sms = shift;

        # Prepare the HTTP request
        my $request = "S=" . $clientType . "&UN=" . $username . "&P=" . $password;
        $request = $request . "&" . $sms->printMessage;

        # Send request
        $s->write_request(GET => "/HTTPSMS?" . $request); 

        # Deal with server response
        my($code, $mess, %h) = $s->read_response_headers;

        if ($code == 200) {
            my $response = "";
            while (1) {
                my $buf;
                my $n = $s->read_entity_body($buf, 1024);
                $errstr = "Read failed; aborting";
                return unless defined $n;
                last unless $n;
                $response = $response . $buf;
            }

            if ($response =~ /OK((\s-?\d+)+)(UR:.*)?/) {
                @replies = split(/\s/, $1);
# This shift saves having to unroll the rexexp once to remove a space
                shift @replies;
                return @replies;
            } else {
                $errstr = "Internal library error, server output not recognised, error";
                return;
            }
        } elsif ($code == 400) {
            $errstr = "(Server) Bad request, error";
            return;
        } elsif ($code == 401) {
            $errstr = "(Server) Invalid username / password. Error in initialise before or";
            return;
        } elsif ($code == 402) {
            $errstr = "(Server) Credit too low, payment required, error";
            return;
        } elsif ($code == 503) {
            $errcode = -15;
            $errstr = "(Server) Destination not recognised, error";
            return;
        } elsif ($code == 500) {
            if ($sms->{RETRY}) {
                $sms->{RETRY} = 0;
                my @r = sendSMS($sms) or $errstr = "Retry failed", return;
                return @r;
            } else {
                $errstr = "(Server) Error, retry failed";
                return;
            }
        } else {
    # Be as verbose as possible in presence of other error
            my $full_response = "";
            while (1) {
                my $fub;
                my $o = $s->read_entity_body($fub, 1024);
                $errstr = "Read from server failed, error";
                return unless defined $o;
                last unless $o;
                $full_response = $full_response . $fub;
            }
            my @lines = split(/\n/, $full_response);
            my $line;
            foreach $line (@lines) {
                print STDERR ">>> $line";
            }
            $errstr = "Internal library error, server error code " . $code . " not recognised. Called from code";
            return;
        }
    } else {
        $errstr = "Number of arguments incorrect. Usage:\n\tSendSMS::sendSMS(destination(s), source, message)\n\tSendSMS::sendSMS(SMS object)\n\nBad usage";
        return;
    }
}

1;
__END__

=head1 SEE ALSO

L<SMS>.

=head1 COPYRIGHT

Copyright 2007 CardBoardFish http://www.cardboardfish.com/

=cut
