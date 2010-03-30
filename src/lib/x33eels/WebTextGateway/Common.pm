package x33eels::WebTextGateway::Common;

use strict;
use warnings;

use WWW::SMS::IE::iesms;
use WWW::SMS::IE::o2sms;
use WWW::SMS::IE::vodasms;
use WWW::SMS::IE::meteorsms;
use SMS::Send;
use SMS::Send::Clickatell;
use Net::SMS::Clickatell;
use Net::Clickatell;
use SMS::Send::AQL;
use SMS::Send::DE::MeinBMW;
use SMS::Send::US::Ipipi;
use SMS::Send::US::Verizon;
use SMS::Send::US::TMobile;
use SMS::Send::AU::MyVodafone;
use SMS::Send::TW::emome;
use SMS::Send::TW::ShareSMS;
use SMS::Send::TW::PChome;
use SMS::Send::TW::HiAir;
use SMS::Send::NL::MyVodafone;
use SMS::Send::NL::Mollie;
use SMS::Send::IS::Vit;
use SMS::Send::IS::Vodafone;
#use SMS::Send::US::SprintPCS;
use SMS::Send::AT::SmsAt;
use WWW::SMS;
#use WWW::SMS::VodafoneIT;
#use WWW::SMS::Tim;
#use WWW::SMS::Alice;
#use WWW::SMS::190;
use WWW::SMS::o2UK;
#use WWW::SMS::O2UK;
#use WWW::SMS::TMobileCZ;
use WWW::SMS::Beeline;
use WWW::SMS::MTS;
#use WWW::SMS::VodafoneES;
#use WWW::SMS::BLR_MTS;
use Net::SMS::ASPSMS;
use Net::SMS::2Way;
use Net::SMS::VoipBuster;
use Net::SMS::MyTMN;
use Net::SMS::MessageNet;
use Net::SMS::Optimus;
use SMS::Claro;
use SMS;
use SendSMS;

@x33eels::WebTextGateway::Common = qw{x33eels::WebTextGateway::Common};

use constant RESULT_MESSAGE_SUCCESS => "success";
use constant RESULT_MESSAGE_ERROR => "error";

use constant RESULT_CODE_SUCCESS => "200";
use constant RESULT_CODE_INVALID_API_KEY => "300";
use constant RESULT_CODE_INVALID_PROVIDER => "310";
use constant RESULT_CODE_MISSING_RECIPIENT => "320";
use constant RESULT_CODE_MISSING_MESSAGE => "330";
use constant RESULT_CODE_LOGIN_FAILED => "340";
use constant RESULT_CODE_SENDING_FAILED_SOME => "350";
use constant RESULT_CODE_SENDING_FAILED_ALL => "351";
use constant RESULT_CODE_INVALID_NUMBER => "360";

use constant CREDENTIALS_PHONE_NUMBER_AND_PASSWORD => "N/P";
use constant CREDENTIALS_PHONE_NUMBER_AND_PIN => "N/#";
use constant CREDENTIALS_EMAIL_ADDRESS_AND_PASSWORD => "E/P";
use constant CREDENTIALS_LOGIN_AND_PASSWORD => "L/P";
use constant CREDENTIALS_USERNAME_PASSWORD_CLIENTID => "U/P/I";
use constant CREDENTIALS_NONE => "N/A";

use constant STATUS_CONFIRMED_WORKING => "201";
use constant STATUS_PROBABLY_WORKING => "202";
use constant STATUS_CONFIRMED_BROKEN => "301";
use constant STATUS_REPORTEDLY_BROKEN => "302";
use constant STATUS_PROBABLY_BROKEN => "303";
use constant STATUS_UNKNOWN => "400";

use constant DEFAULT_FROM => "Sent with WebText";

$x33eels::WebTextGateway::Common::Error = "";

my $providers = ();

$providers->{"dummy"} =
{
	id          => "dummy",
	name        => "Dummy",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_PHONE_NUMBER_AND_PASSWORD,
    format_number => sub 
            {
                my ($number) = @_;
                return $number;
            },
	login       => sub
			{
				sleep 2;
				return 1;
			},
	send        => sub
			{
				sleep 2;
				return 1;
			},
};

$providers->{"o2sms"} =
{
	id          => "o2sms",
	name        => "o2 (IE)",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_PHONE_NUMBER_AND_PASSWORD,
	format_number        => sub
			{
                # number should be "08[678]..." or international;
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return $number if ($number =~ m/^08/);
                return undef;
			},
	login        => sub
			{
				use WWW::SMS::IE::iesms;
				use WWW::SMS::IE::o2sms;
				my ($credential1, $credential2) = @_;
				my $carrier = new WWW::SMS::IE::o2sms;
				if ($carrier->login($credential1, $credential2))
				{
					return $carrier;
				}
				else
				{
					return 0;
				}
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send($recipient, $message);
				if ($retval)
				{
					return 1;
				}
				else
				{
                    $x33eels::WebTextGateway::Common::Error = $carrier->error();
					return 0;
				}
			},
};

$providers->{"vodasms"} =
{
	id          => "vodasms",
	name        => "Vodafone (IE)",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_PHONE_NUMBER_AND_PASSWORD,
	format_number        => sub
			{
                # number should be "08[678]..." 
                my ($number) = @_;
                return $number if ($number =~ m/^08/);
                return $number if ($number =~ m/^+353/);
                return undef;
			},
	login        => sub
			{
				use WWW::SMS::IE::iesms;
				use WWW::SMS::IE::vodasms;
				my ($credential1, $credential2) = @_;
				my $carrier = new WWW::SMS::IE::vodasms;
				if ($carrier->login($credential1, $credential2))
				{
					return $carrier;
				}
				else
				{
					return 0;
				}
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send($recipient, $message);
				if ($retval)
				{
					return 1;
				}
				else
				{
                    $x33eels::WebTextGateway::Common::Error = $carrier->error();
					return 0;
				}
			},
};

$providers->{"meteorsms"} =
{
	id          => "meteorsms",
	name        => "Meteor (IE)",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_PHONE_NUMBER_AND_PIN,
	format_number        => sub
			{
                # number should be "08[678]..." 
                my ($number) = @_;
                return $number if ($number =~ m/^08/);
                return $number if ($number =~ m/^+353/);
                return undef;
			},
	login        => sub
			{
				use WWW::SMS::IE::iesms;
				use WWW::SMS::IE::meteorsms;
				my ($credential1, $credential2) = @_;
				my $carrier = new WWW::SMS::IE::meteorsms;
				if ($carrier->login($credential1, $credential2))
				{
					return $carrier;
				}
				else
				{
					return 0;
				}
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send($recipient, $message);
				if ($retval)
				{
					return 1;
				}
				else
				{
                    $x33eels::WebTextGateway::Common::Error = $carrier->error();
					return 0;
				}
			},
};

$providers->{"clickatell"} =
{
	id          => "clickatell",
	name        => "Clickatell",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_USERNAME_PASSWORD_CLIENTID,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                if ($number =~ m/^\+(\d+)/)
                {
                    return $1;
                }
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3, $credential4) = @_;

				#my $carrier = SMS::Send->new( 'Clickatell',
				#	_user => $credential1,
				#	_password => $credential2,
				#	_api_id => '3137700',
				#	);

                #my $carrier = Net::SMS::Clickatell->new( API_ID => '3137700' );
                #my $retval = $carrier->auth( USER => $credential1, PASSWD => $credential2 );
                #return 0 if ($retval == 0);
                #$credential4 = '3137700';

                my $carrier = Net::Clickatell->new( API_ID => $credential4, USERNAME => $credential1, PASSWORD => $credential2 );

				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3, $credential4) = @_;
				#my $retval = $carrier->send_sms(text => $message, to => $recipient);
                #my $retval = $carrier->sendmsg( TO => $recipient, MSG => $message );
                my $retval = $carrier->sendBasicSMSMessage($credential3, $recipient, $message);

                if ($retval =~ m/^OK/)
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $retval;
                    return 0;
                }
			},
};

$providers->{"aql"} =
{
	id          => "aql",
	name        => "AQL",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'AQL',
					_username => $credential1,
					_password => $credential2,
					_sender => ($credential3?$credential3:$credential1),
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"meinbmw"} =
{
	id          => "meinbmw",
	name        => "MeinBMW (DE)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international or german
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return "+49$number";
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'DE::MeinBMW',
					_login => $credential1,
					_password => $credential2,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"ipipi"} =
{
	id          => "ipipi",
	name        => "ipipi.com",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international 
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                #return $number if ($number =~ m/^\d{10}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'US::Ipipi',
					_login => $credential1,
					_password => $credential2,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"verizon.com"} =
{
	id          => "verizon.com",
	name        => "Verizon (US)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_NONE,
	format_number        => sub
			{
                # number should be us
                my ($number) = @_;
                return $number if ($number =~ m/^\d{10}$/);
                return $number if ($number =~ m/^\+1\d{10}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'US::Verizon' );
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient, _from => "");
				return $retval;
			},
};

$providers->{"t-mobile.com"} =
{
	id          => "t-mobile.com",
	name        => "T-Mobile (US)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_NONE,
	format_number        => sub
			{
                # number should be us
                my ($number) = @_;
                return $number if ($number =~ m/^\d{10}$/);
                return $number if ($number =~ m/^\+1\d{10}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'US::TMobile' );
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient, _from => $credential3);
				return $retval;
			},
};

$providers->{"vodafone.com.au"} =
{
	id          => "vodafone.com.au",
	name        => "Vodafone (AU)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be australian mobile "04..."
                my ($number) = @_;
                return $number if ($number =~ m/^04/);
                if ($number =~ m/^\+614(\d+)/)
                {
                    return "04$1";
                }
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'AU::MyVodafone',
					_login => $credential1,
					_password => $credential2,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"emome"} =
{
	id          => "emome",
	name        => "emome (TW)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'TW::emome',
					_username => $credential1,
					_password => $credential2,
					_language => '2',
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"sharesms.com"} =
{
	id          => "sharesms.com",
	name        => "ShareSMS (TW)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'TW::ShareSMS',
					_username => $credential1,
					_password => $credential2,
					_language   => 'E',
					_region     => 1
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"pchome.com.tw"} =
{
	id          => "pchome.com.tw",
	name        => "PChome (TW)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_USERNAME_PASSWORD_CLIENTID,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'TW::PChome',
					_username => $credential1,
					_password => $credential2,
					_authcode   => $credential3,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"hiair"} =
{
	id          => "hiair",
	name        => "HiAir (TW)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'TW::HiAir',
					_username => $credential1,
					_password => $credential2,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"vodafone.nl"} =
{
	id          => "vodafone.nl",
	name        => "Vodafone (NL)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be dutch mobile number
                my ($number) = @_;
                return $number if ($number =~ m/^\+316\d{8}$/);
                return $number if ($number =~ m/^06\d{8}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'NL::MyVodafone',
					_login => $credential1,
					_password => $credential2,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"mollie"} =
{
	id          => "mollie",
	name        => "Mollie (NL)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be dutch mobile number
                my ($number) = @_;
                return $number if ($number =~ m/^\+316\d{8}$/);
                return $number if ($number =~ m/^06\d{8}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'NL::Mollie',
					_username => $credential1,
					_password => $credential2,
					_originator => $credential3,
					);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"vit.is"} =
{
	id          => "vit.is",
	name        => "Vit (IS)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_NONE,
	format_number        => sub
			{
                # number should be icelandic mobile number
                my ($number) = @_;
                return $number if ($number =~ m/^\+3546\d{6}$/);
                return $number if ($number =~ m/^6\d{6}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'IS::Vit' );
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

$providers->{"vodafone.is"} =
{
	id          => "vodafone.is",
	name        => "Vodafone (IS)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_NONE,
	format_number        => sub
			{
                # number should be icelandic mobile number
                my ($number) = @_;
                return $number if ($number =~ m/^\+3546\d{6}$/);
                return $number if ($number =~ m/^6\d{6}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'IS::Vodafone' );
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

#$providers->{"sprintpcs.com"} =
#{
#	id          => "sprintpcs.com",
#	name        => "Sprint (US)",
#	status      => STATUS_PROBABLY_WORKING,
#	credentials => CREDENTIALS_NONE,
#	login        => sub
#			{
#				my ($credential1, $credential2, $credential3) = @_;
#				my $carrier = SMS::Send->new( 'US::SprintPCS' );
#				return $carrier;
#			},
#	send        => sub
#			{
#				my ($carrier, $message, $recipient) = @_;
#				my $retval = $carrier->send_sms(text => $message, to => $recipient);
#				return $retval;
#			},
#};

$providers->{"sms.at"} =
{
	id          => "sms.at",
	name        => "SMS (AT)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international or austrian
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return "+43$number";
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
				my $carrier = SMS::Send->new( 'AT::SmsAt',
						_login    => $credential1,
						_password => $credential2,
						login    => $credential1,
						password => $credential2,
				);
				return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient) = @_;
				my $retval = $carrier->send_sms(text => $message, to => $recipient);
				return $retval;
			},
};

#$providers->{"vodafoneit"} =
#{
#	id          => "vodafoneit",
#	name        => "Vodafone (IT)",
#	status      => STATUS_PROBABLY_WORKING,
#	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
#	format_number        => sub
#			{
#                # number should be "3934[0789]xxxxxxx";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "39$number" if ($number =~ m/^34[0789]\d{7}$/);
#                return undef if (!$number =~ m/^3934[0789]\d{7}$/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("VodafoneIT");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

#$providers->{"tim"} =
#{
#	id          => "tim",
#	name        => "Tim (IT)",
#	status      => STATUS_PROBABLY_WORKING,
#	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
#	format_number        => sub
#			{
#                # number should be "39xxxxxxxxxx";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "39$number" if ($number =~ m/^\d{10}$/);
#                return undef if (!$number =~ m/^39\d{10}$/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("Tim");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

#$providers->{"alice"} =
#{
#	id          => "alice",
#	name        => "Alice (IT)",
#	status      => STATUS_PROBABLY_WORKING,
#	credentials => CREDENTIALS_NONE,
#	format_number        => sub
#			{
#                # number should be "39xxxxxxxxxx";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "39$number" if ($number =~ m/^\d{10}$/);
#                return undef if (!$number =~ m/^39\d{10}$/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("Alice");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

#$providers->{"190"} =
#{
#	id          => "190",
#	name        => "190 (IT)",
#	status      => STATUS_PROBABLY_WORKING,
#	credentials => CREDENTIALS_NONE,
#	format_number        => sub
#			{
#                # number should be "39xxxxxxxxxx";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "39$number" if ($number =~ m/^\d{10}$/);
#                return undef if (!$number =~ m/^39\d{10}$/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("190");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

$providers->{"o2uk"} =
{
	id          => "o2uk",
	name        => "o2 (UK)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_NONE,
	format_number        => sub
			{
                # number should be "44xxxxxxxxxx";
                my ($number) = @_;
                $number =~ s/^\+//;
                if ($number =~ m/^0(\d{10})$/)
                {
                    $number = "44$1";
                }
                return undef if (!$number =~ m/^44\d{10}$/);
                return $number;
			},
	login        => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient) = @_;
                my $carrier = WWW::SMS->new(
                        $recipient,
                        $message,
                        username => ${$login}[0],
                        passwd => ${$login}[1],
                        );
				my $retval = $carrier->send("o2UK");
                if (!$retval)
                {
                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
                }
                return $retval;
			},
};

#$providers->{"tmobilecz"} =
#{
#	id          => "tmobilecz",
#	name        => "TMobile (CZ)",
#	status      => STATUS_PROBABLY_BROKEN,
#	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
#	format_number        => sub
#			{
#                # number should be "420...";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "420$number" if (!$number =~ m/^420/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("TMobileCZ");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

$providers->{"beeline"} =
{
	id          => "beeline",
	name        => "Beeline (RU)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be "7...";
                my ($number) = @_;
                $number =~ s/^\+//;
                $number = "7$number" if (!$number =~ m/^7/);
                return undef if (!$number =~ m/^7(095|901|903)/);
                return $number;
			},
	login        => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient) = @_;
                my $carrier = WWW::SMS->new(
                        $recipient,
                        $message,
                        username => ${$login}[0],
                        passwd => ${$login}[1],
                        );
				my $retval = $carrier->send("Beeline");
                if (!$retval)
                {
                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
                }
                return $retval;
			},
};

$providers->{"mts"} =
{
	id          => "mts",
	name        => "MTS (RU)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_NONE,
	format_number        => sub
			{
                # number should be "7...";
                my ($number) = @_;
                $number =~ s/^\+//;
                $number = "7$number" if (!$number =~ m/^7/);
                return undef if (!$number =~ m/^7(095|902|910)/);
                return $number;
			},
	login        => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient) = @_;
                my $carrier = WWW::SMS->new(
                        $recipient,
                        $message,
                        username => ${$login}[0],
                        passwd => ${$login}[1],
                        );
				my $retval = $carrier->send("MTS");
                if (!$retval)
                {
                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
                }
                return $retval;
			},
};

#$providers->{"vodafonees"} =
#{
#	id          => "vodafonees",
#	name        => "Vodafone (ES)",
#	status      => STATUS_PROBABLY_BROKEN,
#	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
#	format_number        => sub
#			{
#                # number should be "34xxxxxxxxx";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "34$number" if ($number =~ m/^\d{9}$/);
#                return undef if (!$number =~ m/^34\d{9}$/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("VodafoneES");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

#$providers->{"blr_mts"} =
#{
#	id          => "blr_mts",
#	name        => "MTS (BY)",
#	status      => STATUS_PROBABLY_BROKEN,
#	credentials => CREDENTIALS_NONE,
#	format_number        => sub
#			{
#                # number should be "375...";
#                my ($number) = @_;
#                $number =~ s/^\+//;
#                $number = "375$number" if (!$number =~ m/^375/);
#                return undef if (!$number =~ m/^375(297|295|292)/);
#                return $number;
#			},
#	login        => sub
#			{
#                return \@_;
#			},
#	send        => sub
#			{
#				my ($login, $message, $recipient) = @_;
#                my $carrier = WWW::SMS->new(
#                        $recipient,
#                        $message,
#                        username => ${$login}[0],
#                        passwd => ${$login}[1],
#                        );
#				my $retval = $carrier->send("BLR_MTS");
#                if (!$retval)
#                {
#                    $x33eels::WebTextGateway::Common::Error = $WWW::SMS::Error;
#                }
#                return $retval;
#			},
#};

$providers->{"aspsms"} =
{
	id          => "aspsms",
	name        => "aspsms.com",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $carrier = new Net::SMS::ASPSMS(
                        userkey => $credential1,
                        password => $credential2,
                        );
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                $carrier->send_text_sms(
                        Recipient_PhoneNumber => $recipient,
                        Originator => $credential3,
                        MessageData => $message,
                        );
                $x33eels::WebTextGateway::Common::Error = $carrier->result->{ErrorDescription};
                return ($carrier->result->{ErrorDescription}eq"");
			},
};

$providers->{"2way"} =
{
	id          => "2way",
	name        => "2way (ZA)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international or south african
                my ($number) = @_;
                if ($number =~ m/^0([87]\d+)/)
                {
                    $number = "+27$1";
                }
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $carrier = Net::SMS::2Way->new({username => $credential1, password => $credential2});
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                my $retval = $carrier->send_sms($message, $recipient);
                my ($status_code, $status_desc, $batch_id) = split( /\|/, $retval);
                if ($status_code == 0 || $status_code == 1)
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $status_desc;
                    return 0;
                }
			},
};

$providers->{"voipbuster"} =
{
	id          => "voipbuster",
	name        => "VoipBuster",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $carrier = Net::SMS::VoipBuster->new($credential1, $credential2, "voipbuster.com");
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                my $retval = $carrier->send($message, $recipient, $credential3);
                if ($retval == 1)
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $retval->{"error"};
                    return 0;
                }
			},
};

$providers->{"voipcheap"} =
{
	id          => "voipcheap",
	name        => "VoipCheap",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $carrier = Net::SMS::VoipBuster->new($credential1, $credential2, "voipcheap.com");
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                my $retval = $carrier->send($message, $recipient, $credential3);
                if ($retval == 1)
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $retval->{"error"};
                    return 0;
                }
			},
};

$providers->{"voipstunt"} =
{
	id          => "voipstunt",
	name        => "VoipStunt",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $carrier = Net::SMS::VoipBuster->new($credential1, $credential2, "voipstunt.com");
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                my $retval = $carrier->send($message, $recipient, $credential3);
                if ($retval == 1)
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $retval->{"error"};
                    return 0;
                }
			},
};

$providers->{"smsdiscount"} =
{
	id          => "smsdiscount",
	name        => "SMSDiscount",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $carrier = Net::SMS::VoipBuster->new($credential1, $credential2, "smsdiscount.com");
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                my $retval = $carrier->send($message, $recipient, $credential3);
                if ($retval == 1)
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $retval->{"error"};
                    return 0;
                }
			},
};



$providers->{"mytmn"} =
{
	id          => "mytmn",
	name        => "TMN (PT)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international or portuguese
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return "+351$number";
			},
	login        => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient, $credential3) = @_;
                my $retval = Net::SMS::MyTMN::sms_mytmn(
                        {
                        'username' => ${$login}[0],
                        'password' => ${$login}[1],
                        'targets' => [$recipient],
                        'message' => $message,
                        }
                        );
                if ($retval eq "Message sent")
                {
                    return 1;
                }
                else
                {
                    $x33eels::WebTextGateway::Common::Error = $retval;
                    return 0;
                }
			},
};

$providers->{"messagenet"} =
{
	id          => "messagenet",
	name        => "MessageNet (AU)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international or australian
                my ($number) = @_;
                if ($number =~ m/^0([4]\d+)/)
                {
                    $number = "+61$1";
                }
                return $number if ($number =~ m/^\+/);
                return undef;
			},
    login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                return Net::SMS::MessageNet->new($credential1, $credential2);
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                eval
                {
                    $carrier->send($recipient, $message);
                };
                if ($@)
                {
                    $x33eels::WebTextGateway::Common::Error = $@;
                    return 0;
                }
                return 1;
			},
};

$providers->{"optimus"} =
{
	id          => "optimus",
	name        => "Optimus (PT)",
	status      => STATUS_PROBABLY_BROKEN,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be portuguese
                my ($number) = @_;
                if ($number =~ m/^\+351(93.*)/)
                {
                    return $1;
                }
                elsif ($number =~ m/^93(\d{7})$/)
                {
                    return $number;
                }
                else
                {
                    return undef;
                }
			},
	login        => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient, $credential3) = @_;
                eval
                {
                    send_sms(${$login}[0], ${$login}[1], [$recipient], $message);
                };
                if ($@)
                {
                    $x33eels::WebTextGateway::Common::Error = $@;
                    return 0;
                }
                return 1;
			},
};

$providers->{"claro"} =
{
	id          => "claro",
	name        => "Claro (BR)",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be brazilian
                my ($number) = @_;
                return $number if ($number =~ m/^1\d{10}$/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $sms = new SMS::Claro;
                $sms->login($credential1, $credential2);
                return $sms;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                $carrier->from($credential3);
                $carrier->to($recipient);
                $carrier->send($message);
                if (!$carrier->is_success)
                {
                    return 0;
                }
                return 1;
			},
};

$providers->{"cardboardfish"} =
{
	id          => "cardboardfish",
	name        => "CardboardFish",
	status      => STATUS_PROBABLY_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
	format_number        => sub
			{
                # number should be international
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return undef;
			},
	login        => sub
			{
				my ($credential1, $credential2, $credential3) = @_;
                my $retval = SendSMS::initialise($credential1, $credential2);
		if (!$retval)
		{
			$x33eels::WebTextGateway::Common::Error = SendSMS->errstr;
			return undef;
		}
                my $carrier = new SMS();
                $credential3 =~ s/^\+//;
                $retval = $carrier->setSA($credential3);
		if (!$retval)
		{
			$x33eels::WebTextGateway::Common::Error = $carrier->errstr;
			return undef;
		}
                return $carrier;
			},
	send        => sub
			{
				my ($carrier, $message, $recipient, $credential3) = @_;
                $recipient =~ s/^\+//;
                my $retval = $carrier->setDA($recipient);
                if (!$retval)
                {
                    $x33eels::WebTextGateway::Common::Error = $carrier->errstr;
                    return 0;
                }
                $retval = $carrier->setMSG($message);
                if (!$retval)
                {
                    $x33eels::WebTextGateway::Common::Error = $carrier->errstr;
                    return 0;
                }
		$retval = SendSMS::sendSMS($carrier);
                if (!$retval)
                {
                    $x33eels::WebTextGateway::Common::Error = SendSMS->errstr;
                    return 0;
                }

                return 1;
			},
};

$providers->{"smsout.de"} =
{
	id          => "smsout.de",
	name        => "SMSout.de",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
    format_number => sub 
            {
                # number should be international or german
                my ($number) = @_;
                return $number if ($number =~ m/^\+/);
                return "+49$number";
            },
	login       => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient) = @_;
                my $ua = LWP::UserAgent->new(agent=>'x33eels::WebTextGateway');
                my $response = $ua->post('https://www.smsout.de/client/sendsms.php',
                    {
                        Username => ${$login}[0],
                        Password => ${$login}[1],
                        SMSTo => $recipient,
                        SMSType => 'V1',
                        SMSText => $message
                    });
                my $content = $response->content;

                if ($content =~ m/Return:\s*OK/gi)
                {
                    return 1;
                }
                elsif ($content =~ m/ErrorText:\s*(.*)/gi)
                {
                    my $err = $1;
                    chop($err);
                    $x33eels::WebTextGateway::Common::Error = $err;
                    return 0;
                }
                else
                {
                    return 0;
                }
			},
};

$providers->{"sipgate"} =
{
	id          => "sipgate",
	name        => "sipgate",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
    format_number => sub 
            {
                my ($number) = @_;
                $number =~ s/^\+//;
                return $number;
            },
	login       => sub
			{
				my ($credential1, $credential2) = @_;
                my $url = "https://$credential1:$credential2\@samurai.sipgate.net/RPC2";
                my $xmlrpc_client = Frontier::Client->new( 'url' => $url );

                my $args_identify = { ClientName => "x33eels::WebtextGateway", ClientVersion => "1.0", ClientVendor => "33eels" };
                my $xmlrpc_result = $xmlrpc_client->call( "samurai.ClientIdentify", $args_identify );

                if ($xmlrpc_result->{'StatusCode'} == 200)
                {
                    return $xmlrpc_client;
                }
                else
                {
                    return 0;
                }
			},
	send        => sub
			{
				my ($xmlrpc_client, $message, $recipient) = @_;
                my $args = { RemoteUri => "sip:$recipient\@sipgate.net", TOS => "text", Content => $message };
                my $xmlrpc_result = $xmlrpc_client->call( "samurai.SessionInitiate", $args );

                if ($xmlrpc_result->{'StatusCode'} == 200)
                {
                    return 1;
                }
                else
                {
                    return 0;
                }
			}, 
};


$providers->{"hostindia"} =
{
	id          => "hostindia",
	name        => "HostIndia.net",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_USERNAME_PASSWORD_CLIENTID,
    format_number => sub 
            {
                # number should be indian
                my ($number) = @_;
                $number =~ s/^\+91/91/;
                return $number if ($number =~ m/^91\d{10}$/);
                return undef;
            },
	login       => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient) = @_;
                my $ua = LWP::UserAgent->new(agent=>'x33eels::WebTextGateway');
                my $response = $ua->post('http://freedom.hostinservices.com/user/api.php',
                    {
                        username => ${$login}[0],
                        password => ${$login}[1],
                        mode => 'smspush',
                        op => 'send_sms',
                        sms_from => (${$login}[2]?${$login}[2]:"Web"),
                        sms_to => $recipient,
                        sms_type => 'T',
                        sms_message => $message
                    });
                my $content = $response->content;

                if ($content =~ m/<status>SUCCESS<\/status>/gi)
                {
                    return 1;
                }
                elsif ($content =~ m/<status_message>(.*)<\/status_message>/gi)
                {
                    my $err = $1;
                    $x33eels::WebTextGateway::Common::Error = $err;
                    return 0;
                }
                else
                {
                    return 0;
                }
			},
};

$providers->{"mediaburst"} =
{
	id          => "mediaburst",
	name        => "Mediaburst.co.uk",
	status      => STATUS_CONFIRMED_WORKING,
	credentials => CREDENTIALS_LOGIN_AND_PASSWORD,
    format_number => sub 
            {
                my ($number) = @_;
                $number =~ s/^\+//;
                return $number;
            },
	login       => sub
			{
                return \@_;
			},
	send        => sub
			{
				my ($login, $message, $recipient) = @_;
                my $ua = LWP::UserAgent->new(agent=>'x33eels::WebTextGateway');
                my $response = $ua->get('https://sms.message-platform.com/http/send.aspx',
                        Username => ${$login}[0],
                        Password => ${$login}[1],
                        To => $recipient,
                        From => ${$login}[2],
                        Content => $message,
                        MsgType => 'TEXT',
                        ClientID => 'webtext-' + time()
                    );
                my $content = $response->content;

                if ($content =~ m/ID: [\w\d_]+/gi)
                {
                    return 1;
                }
                elsif ($content =~ m/Error \d+: (.*)/gi)
                {
                    my $err = $1;
                    chop($err);
                    $x33eels::WebTextGateway::Common::Error = $err;
                    return 0;
                }
                else
                {
                    return 0;
                }
			},
};


my @valid_api_keys = ("9019b3509f83210d5fbf59f70ef7f25a");

sub get_providers
{
	return $providers;
}

sub get_valid_api_keys
{
	return @valid_api_keys;
}

