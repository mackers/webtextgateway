package SMS;

=head1 NAME

SMS - A class for representing SMS messages

=head1 SYNOPSIS

use B<SMS>;

my $sms1 = new B<SMS>(destination, source, message);

my $sms2 = new B<SMS>(destination, source, source type,
message, data coding scheme, delivery receipt request, user data header,
user reference, validity period, delay until, local time);

my $sms3 = new B<SMS>();
$sms3->setDC(0);

=head1 DESCRIPTION

Instances of this class are used to represent SMS messages within the
system. This API provides greater control and flexibility over the
sending of messages, at the cost of simplicity. The fields and flags
are all sensitive to their own validation, and must be used as
described. An SMS object cannot be created with invalid fields,
and any attempt to use the mutators incorrectly will cause them to fail.

It is important that all uses of these objects and their methods are
checked with "or B<die>" style code; otherwise, the module may not
appear to behave as you expect.

=cut

use strict;
use 5.6.8;

use vars qw($VERSION @ISA @EXPORT);

use Encode;

require Exporter;

$VERSION = '1.0';

my $errstr;

sub errstr {
    if (!defined($errstr)) {
        return "No (SMS) error. Called from code";
    }
    return $errstr;
}

my %gsmchar = (
    "\x{000A}" => "\x0A",
    "\x{000D}" => "\x0D",
    "\x{20AC}" => "\x1B\x65",

    "\x{0013}" => "\x{0013}",
    "\x{0010}" => "\x{0010}",
    "\x{0019}" => "\x{0019}",
    "\x{0014}" => "\x{0014}",
    "\x{001A}" => "\x{001A}",
    "\x{0016}" => "\x{0016}",
    "\x{0018}" => "\x{0018}",
    "\x{0012}" => "\x{0012}",
    "\x{0017}" => "\x{0017}",
    "\x{0015}" => "\x{0015}",

    "\x{00A1}" => "\x40",
    "\x{00A3}" => "\x01",
    "\x{00A4}" => "\x1B\x65",
    "\x{0080}" => "\x1B\x65",
    "\x{00A5}" => "\x03",
    "\x{00A7}" => "\x5F",
    "\x{00BF}" => "\x60",
    "\x{0024}" => "\x02",

    "\x{00C0}" => "\x41",  # A
    "\x{00C1}" => "\x41",  # A
    "\x{00C2}" => "\x41",  # A
    "\x{00C3}" => "\x41",  # A
    "\x{00C4}" => "\x5B",
    "\x{00C5}" => "\x0E",
    "\x{00C6}" => "\x1C",
    "\x{00C7}" => "\x09",
    "\x{00C8}" => "\x45",  # E
    "\x{00C9}" => "\x1F",
    "\x{00CA}" => "\x45",  # E
    "\x{00CB}" => "\x45",  # E
    "\x{00CC}" => "\x49",  # I
    "\x{00CD}" => "\x49",  # I
    "\x{00CE}" => "\x49",  # I
    "\x{00CF}" => "\x49",  # I

    "\x{00D0}" => "\x44",  # D
    "\x{00D1}" => "\x5D",
    "\x{00D2}" => "\x4F",  # O
    "\x{00D3}" => "\x4F",  # O
    "\x{00D4}" => "\x4F",  # O
    "\x{00D5}" => "\x4F",  # O
    "\x{00D6}" => "\x5C", 
    "\x{00D8}" => "\x0B",
    "\x{00D9}" => "\x55",  # U
    "\x{00DA}" => "\x55",  # U
    "\x{00DB}" => "\x55",  # U
    "\x{00DC}" => "\x5E",
    "\x{00DD}" => "\x59",  # Y
    "\x{00DF}" => "\x1E",

    "\x{00E0}" => "\x7F",
    "\x{00E1}" => "\x61",  # a
    "\x{00E2}" => "\x61",  # a
    "\x{00E3}" => "\x61",  # a
    "\x{00E4}" => "\x7B",
    "\x{00E5}" => "\x0F", 
    "\x{00E6}" => "\x1D", 
    "\x{00E7}" => "\x63",  # c
    "\x{00E8}" => "\x04",
    "\x{00E9}" => "\x05",
    "\x{00EA}" => "\x65",  # e
    "\x{00EB}" => "\x65",  # e
    "\x{00EC}" => "\x07",
    "\x{00ED}" => "\x69",  # i
    "\x{00EE}" => "\x69",  # i
    "\x{00EF}" => "\x69",  # i

    "\x{00F0}" => "\x64",  # d
    "\x{00F1}" => "\x7D", 
    "\x{00F2}" => "\x08",
    "\x{00F3}" => "\x6F",  # o
    "\x{00F4}" => "\x6F",  # o
    "\x{00F5}" => "\x6F",  # o
    "\x{00F6}" => "\x7C",
    "\x{00F8}" => "\x0C",
    "\x{00F9}" => "\x06", 
    "\x{00FA}" => "\x75",  # u
    "\x{00FB}" => "\x75",  # u
    "\x{00FC}" => "\x7E",
    "\x{00FD}" => "\x79", 

    "[" => "\x1B\x3C",
    "\\" => "\x1B\x2F",
    "]" => "\x1B\x3E",
    "^" => "\x1B\x14",
    "_" => "\x11",
    "{" => "\x1B\x28",
    "|" => "\x1B\x40",
    "}" => "\x1B\x29",
    "~" => "\x1B\x3D",
    "@" => "\x00"
);

sub GSMEncode {
    my $to_encode = shift;

    my @chars = split(//, $to_encode);

    my $to_return = "";
    my $char;
    foreach $char (@chars) {
        if ($char =~ /[A-Za-z0-9!\/#%&"=\-'\<>?\(\)\*\+\,\.;:]/) {
            $to_return .= $char;
        } else {
            my $repchar = $gsmchar{$char};
            if (defined $repchar) {
                $to_return .= $repchar;
            } else {
                $to_return .= "\x20";
            }
        }
    }

    return $to_return;
}

sub URLEncode {
    my $to_encode = shift;
    $to_encode =~ s/([^A-Za-z0-9\x20])/sprintf("%%%02X", ord($1))/seg;
    $to_encode =~ s/\x00/%00/sg;
    $to_encode =~ s/\x20/+/sg;
    return $to_encode;
}

=head1 CREATING SMS OBJECTS

The constructor can be used in three forms, as shown in the synopsis
above. The first form is the simplest; it creates an SMS object with
the three required fields, and sets sensible defaults for the others.
The destination field should contain one or more phone numbers, in a
string, separated by commas. The source field describes the sender;
this is usually a phone number or service provider name.

If created in this manner, the message will be assumed to have normal
encoding. To set a different encoding, the Data Coding Scheme must be
specified (see below).

=cut

sub new {
    my $self = bless {}, shift;
    my $argc = @_;

    if ($argc == 0) {
        return $self;
    } elsif ($argc == 3) {
        my ($da, $sa, $msg) = @_;
        my $full_sms = SMS->new($da, $sa, "", $msg, "", "", "", "", "", "", "") or return;
        return $full_sms;
    } elsif ($argc == 11) {
        my ($da, $sa, $sat, $msg, $dcs, $dr, $udh, $ur, $vp, $du, $lt) = @_;

        $self->setDA($da) or return;
        $self->setSA($sa) or return;
        $self->setST($sat) or return;
        $self->setMSG($msg) or return;
        $self->setDC($dcs) or return;
        $self->setDR($dr) or return;
        $self->setUD($udh) or return;
        $self->setUR($ur) or return;
        $self->setVP($vp) or return;
        $self->setDU($du) or return;
        $self->setLT($lt) or return;

        $self->{RETRY} = 1;
        return $self;
    } else {
        $errstr = "Construction failed. Usage:\n\tSMS->new();\n\tSMS->new(destination(s), source, message);\n\tSMS->new(destination(s), source, sourceaddrton,\n\t\tmessage, data_coding, delivery_receipt_request,\n\t\tuser_header_data, user_reference, validity_period,\n\t\tdelay_until, local_time)\n\nBad usage";
        return;
    }
}

=head1 DESTINATION ADDRESS

This method sets the destination addresses for the object. Numbers
must be given in international format without the leading +.

    $sms->setDA("441234567890,449876543210") or die ($sms->errstr);

As you can see, multiple addresses are given as a comma separated list.

=cut

sub setDA {
    my $self = shift;
    my $da = shift;

    my @das = split(/,/, $da);

    my @valid_dests = ();

    foreach my $dest (@das) {
        if ($dest =~ m/^(\+|00)?([1-9][0-9]{7,15})*$/) {
            push(@valid_dests, $2);
        } else {
            $errstr = "Destination not recognised.";
            return;
        }
    }
    $self->{DESTADDR} = join(",", @valid_dests);
    return 1;
}

=head1 SOURCE ADDRESS

The source address is usually a phone number or a company or service
name. This method sets the source address field. Numbers can be
16 digits long; names must be no longer than 11.

    $sms->setSA("SMS_Service") or die ($sms->errstr);

=cut

sub setSA {
    my $self = shift;
    my $sa = shift;

    if ($sa =~ /^([0-9]{1,16}|^.{1,11})$/) {
        $self->{SOURCEADDR} = URLEncode(GSMEncode($sa));
        return 1;
    } else {
        $errstr = "Source address not recognised, error";
        return;
    }
}

=head1 SOURCE NUMBER TYPE

The setST method sets the source number type. Must be one of:

=over

=item * 0 - National numeric

=item * 1 - International numeric

=item * 5 - Alphanumeric

=back

For example:

    $sms->setST(1) or die ($sms->errstr);

=cut

sub setST {
    my $self = shift;
    my $st = shift;

    if ($st =~ /^.+$/) {

        if ($st =~ /^[105]$/) {
            $self->{SOURCEADDRTON} = $st;
            return 1;
        } else {
            $errstr = "SourceAddrTON must be 1, 0 or 5, error";
            return;
        }

    } else {
        $self->{SOURCEADDRTON} = "";
        return 1;
    }

}

=head1 DATA CODING SCHEME

The method setDC sets the data coding scheme. Must be one of:

=over

=item * 0 - Flash

=item * 1 - Normal (default)

=item * 2 - Binary

=item * 4 - UCS2

=item * 5 - Flash UCS2

=item * 6 - Flash GSM

=item * 7 - Normal GSM

=back

For example:

    $sms->setDC(0) or die ($sms->errstr);

=cut

sub setDC {
    my $self = shift;
    my $dcs = shift;

    if ($dcs =~ /^.+$/) {
        if ($dcs =~ /^[0124567]$/) {
            $self->{DC} = $dcs;
            return 1;
        } else {
            $errstr = "DC must be 0-7 and not 3, error";
            return;
        }
    } else {
        $self->{DC} = "";
        return 1;
    }
}

=head1 DELIVERY RECEIPT REQUEST

This sets the field to request delivery receipts. Must be one of:

=over

=item * 0 - No (default)

=item * 1 - Yes

=item * 2 - Record only

=back

For example:

    $sms->setDR(1);

=cut

sub setDR {
    my $self = shift;
    my $dr = shift;

    if ($dr =~ /^.+$/) {
        if ($dr =~ /^[0-2]$/) {
            $self->{DR} = $dr;
			return 1;
		} else {
			$errstr = "Delivery receipt request must be 0-2, error";
			return;
		}
	} else {
		$self->{DR} = "";
		return 1;
	}
}

=head1 USER DATA HEADER

Sets a user data header. Should be given in hexadecimal. Example:

    $sms->setUD("78a7dc7d7665ca");

=cut

sub setUD {
    my $self = shift;
    my $udh = shift;

    if ($udh =~ /^.+$/) {
        if ($udh =~ /^[0-9a-fA-F]{1,17}$/) {
            $self->{UD} = $udh;
            return 1;
        } else {
            $errstr = "User header data invalid, error";
            return;
        }
    } else {
        $self->{UD} = $udh;
        return 1;
    }
}

=head1 USER REFERENCE

The method setUR sets a user reference. This is used to aid with
matching delivery receipts. Maximum 16 characters.

For example:

    $sms->setUR("MyRef12345") or die ($sms->errstr);

=cut

sub setUR {
    my $self = shift;
    my $ur = shift;

    if ($ur =~ /^.+$/) {
        if ($ur =~ /^\w{1,16}$/) {
            $self->{USERREFERENCE} = $ur;
            return 1;
        } else {
            $errstr = "User reference invalid. Must be 1-16 chars. Error";
            return;
        }
    } else {
        $self->{USERREFERENCE} = "";
        return 1;
    }
}

=head1 VALIDITY PERIOD

To set the validity period, use the setVP method. The validity period
specifies the number of minutes for which to attempt delivery before
the message expires. Maximum 10080, default 1440.

For example:

    $sms->setVP(5000) or die ($sms->errstr);

=cut

sub setVP {
    my $self = shift;
    my $vp = shift;

    if ($vp =~ /^.+$/) {
        if ($vp =~ /^\d+$/) {
            if (0 <= $vp && $vp <= 10080) {
                $self->{VALIDITYPERIOD} = $vp;
                return 1;
            } else {
                $errstr = "Validity period must be between 0 and 10080. Error";
                return;
            }
        } else {
            $errstr = "Validity period must be a number. Error";
            return;
        }
    } else {
        $self->{VALIDITYPERIOD} = "";
        return 1;
    }
}

=head1 DELAY UNTIL

If the message is to be delivered at a later time, this field specifies
it, as a 10 digit UCS timestamp. This works relative to local time,
which can be specified as below. The delay time is set with setDU:

    $sms->setDU("1234567890") or die ($sms->errstr);

=cut

sub setDU {
    my $self = shift;
    my $du = shift;

    if ($du =~ /^.+$/) {
        if ($du =~ /^\d{10}$/) {
            $self->{DELAYUNTIL} = $du;
            $self->setLT("");
            return 1;
        } else {
            $errstr = "Delay Until must be a 10 digit UCS timestamp. Error";
            return;
        }
    } else {
        $self->{DELAYUNTIL} = "";
        return 1;
    }
}

=head1 LOCAL TIME

To set the local time, use the setLT method. This should also be a 10
digit UCS timestamp.

    $sms->setLT("2234567890");

=cut

sub setLT {
    my $self = shift;
    my $lt = shift;

    if ($lt =~ /^.+$/) {
        if ($lt =~ /^\d{10}$/) {
            $self->{LOCALTIME} = $lt;
            return 1;
        } else {
            $errstr = "Local Time must be a 10 digit UCS timestamp. Error";
            return;
        }
    } else {
        if ($self->{DELAYUNTIL} =~ /^.+$/) {
            $self->{LOCALTIME} = time();
            return 1;
        } else {
            $self->{LOCALTIME} = "";
            return 1;
        }
    }
}

=head1 MESSAGE

The message itself is given with the setMSG method. This message should
already be encoded according to the scheme specified with setDC (if
given). The message must be given on all SMS objects before sending
with sendSMS is attempted.

Example:

    $sms->setDC(1);
    $sms->setMSG("This is my message.");

=cut

sub setMSG {
    my $self = shift;
    my $message = shift;

    $self->{MESSAGE} = $message;

    return 1;
}

sub printMessage {
    my $self = shift;

    my $required = "DA=" . $self->{DESTADDR} . "&SA=" . $self->{SOURCEADDR} . "&M=";

    my $dcs = $self->{DC};
    if ($dcs =~ /^.+$/) {
        if ($dcs == 0) {
            $dcs = 7;
            $required .= URLEncode(GSMEncode($self->{MESSAGE}));
        } elsif ($dcs == 1) {
            $dcs = 6;
            $required .= URLEncode(GSMEncode($self->{MESSAGE}));
        } else {
            $required .= URLEncode($self->{MESSAGE});
        }
    } else {
        $dcs = 6;
        $required .= URLEncode(GSMEncode($self->{MESSAGE}));
    }

    my $optional = "";

    if ($self->{SOURCEADDRTON} =~ /^.+$/) {
        $optional .= "&ST=" . $self->{SOURCEADDRTON};
    } elsif ($self->{SOURCEADDR} =~ /[^0-9]/) {
        $optional .= "&ST=5";
    }

    if ($dcs =~ /^.+$/) {
        $optional .= "&DC=" . $dcs;
    }

    if ($self->{DR} =~ /^.+$/) {
        $optional .= "&DR=" . $self->{DR};
    }

    if ($self->{USERREFERENCE} =~ /^.+$/) {
        $optional .= "&UR=" . $self->{USERREFERENCE};
    }

    if ($self->{VALIDITYPERIOD} =~ /^.+$/) {
        $optional .= "&V=" . $self->{VALIDITYPERIOD};
    }

    if ($self->{DELAYUNTIL} =~ /^.+$/) {
        $optional .= "&DU=" . $self->{DELAYUNTIL};
    }

    if ($self->{UD} =~ /^.+$/) {
        $optional .= "&UD=" . $self->{UD};
    }

    if ($self->{LOCALTIME} =~ /^.+$/) {
        $optional .= "&LT=" . $self->{LOCALTIME};
    }

    return $required . $optional;
}

1;
__END__

=head1 SEE ALSO

L<SendSMS>.

=head1 COPYRIGHT

Copyright 2007 CardBoardFish http://www.cardboardfish.com/

=cut
