package ClientPolled;

=head1 NAME

ClientPolled - A module for interacting with HTTPSMS servers

=head1 SYNOPSIS

use B<ClientPolled>;

B<ClientPolled::initialise>(username, password);

my $responses = B<ClientPolled::poll>();

=head1 DESCRIPTION

This module can be used by clients who need to poll the HTTPSMS server
for delivery receipt information. A valid username and password are
required for the use of this module. Once used to initialise the module,
the username and password will be used in all communications with the
server.

=cut

use strict;
use 5.6.8;

use vars qw($VERSION @ISA @EXPORT);

use Net::HTTP;
use IncomingFormat;

require Exporter;

$VERSION = '1.0';

my $errstr;

sub errstr {
    if (!defined($errstr)) {
        return "No (ClientPolled) error. Called from code";
    }
    return $errstr;
}

my $username = "";
my $password = "";

=head1 INITIALISATION

To initialise the module, simply call the initialise subroutine with your username and password:

    ClientPolled::initialise("myUsername", "mypass");

It is best to check that no problems have been detected during this
step, using the standard "or B<die>" approach:

    ClientPolled::initialise("myUsername", "mypass")
      or die (ClientPolled->errstr);

=cut

sub initialise {
    my ($un, $passwd) = @_;
    if ($un && $passwd) {
        ($username, $password) = ($un, $passwd);
        return 1;
    } else {
        $errstr = "Username and password must not be empty, error";
        return;
    }
}

=head1 POLLING

After initialisation simply call the B<poll> method to check for
information:

    my $messages = ClientPolled::poll();

=cut

sub poll {
    $errstr = "Could not connect to server. Called from code";
    my $s = Net::HTTP->new(Host => "sms1.cardboardfish.com:9001") or return;
    undef $errstr;

    my @replies;

    # These two lines should enable persistent connections:
    $s->http_version(1.1);
    $s->keep_alive("TRUE");

    # Prepare the HTTP request
    my $request = 'UN=' . $username . '&P=' . $password;

    # Send request
    $s->write_request(GET => "/ClientDR/ClientDR?" . $request); 

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

        return IncomingFormat::processIncoming($response);
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
        $errstr = "(Server) Destination not recognised, error";
        return;
    } elsif ($code == 500) {
        $errstr = "(Server) Internal Server Error";
        return;
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
}

1;
__END__

=head1 SEE ALSO

L<SMS>.

=head1 COPYRIGHT

Copyright 2007 CardBoardFish http://www.cardboardfish.com/

=cut
