package x33eels::WebTextGateway::Send;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Log;
use Apache2::Const -compile => qw(OK :log);
use APR::Const    -compile => qw(SUCCESS);
use IO::String;

use x33eels::WebTextGateway::Common;

use CGI::as_utf8;

sub handler
{
	my $r = shift;

	$r->content_type("application/xml");

	# process arguments

	my $query = new CGI;

	if ($query->request_method ne "POST")
	{
		return die_with_message("1001");
	}

	my $api_key = $query->param('api_key');
	my $credential1 = $query->param('credential1');
	my $credential2 = $query->param('credential2');
	my $credential3 = $query->param('credential3');
	my $credential4 = $query->param('credential4');
	my $provider_id = $query->param('provider');
	my $message = $query->param('message');
	my @recipients = $query->param('recipient');

	if (!check_api_key($api_key))
	{
		$r->log_reason("Invalid API key: $api_key");
		return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_INVALID_API_KEY);
	}

	my $provider = get_provider($provider_id);

	if (!$provider)
	{
		$r->log_reason("Invalid Provider: $provider");
		return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_INVALID_PROVIDER);
	}

	if (scalar(@recipients) == 0)
	{
		$r->log_reason("Missing Recipients");
		return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_MISSING_RECIPIENT);
	}

	my $format_number_sub = $provider->{"format_number"};
    my @formatted_recipients = ();

	for my $recipient (@recipients)
	{
        my $formatted_number = $recipient;

        # change '00' style numbers to '+' style 
        $formatted_number =~ s/^00/+/;

        # remove any non-numeric characters
        $formatted_number =~ s/[^\+\d]//;
        
        $formatted_number = &$format_number_sub($formatted_number);

        if (!defined($formatted_number))
        {
            $r->log_reason("Invalid Number");
            return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_INVALID_NUMBER, "Invalid Number: $recipient");
        }

        push(@formatted_recipients, $formatted_number);
	}

	if (!$message)
	{
		$r->log_reason("Missing Message");
        $message = " ";
	#	return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_MISSING_MESSAGE);
	}

	# login

	my $login_sub = $provider->{"login"};

	$r->log_rerror(Apache2::Log::LOG_MARK, Apache2::Const::LOG_DEBUG, APR::Const::SUCCESS,
		"Logging in with credentials: '$credential1', '$credential2', '$credential3', '$credential4'");

	my $session;

    # capture stdout so modules don't break our api

    my $str;
    my $str_fh = IO::String->new($str);
    my $old_fh = select($str_fh);

	eval
	{
		$session = &$login_sub($credential1, $credential2, $credential3, $credential4);
	};

    select($old_fh) if defined $old_fh;

    if ($str && $str ne "")
    {
        $r->log_rerror(Apache2::Log::LOG_MARK, Apache2::Const::LOG_DEBUG, APR::Const::SUCCESS, "Module said: '$str'");
    }

	if (!$session || $@)
	{
		$r->log_reason($provider->{"id"}. ": Login Failed: '" . $@ . "'");
		return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_LOGIN_FAILED, "Login Failed");
	}

	# send

	my $has_sent = 0;

	my $send_sub = $provider->{"send"};

	for my $recipient (@formatted_recipients)
	{
		$r->log_rerror(Apache2::Log::LOG_MARK, Apache2::Const::LOG_DEBUG, APR::Const::SUCCESS,
			"Sending message '$message' to recipient '$recipient'");

        # capture stdout so modules don't break our api

        my $str;
        my $str_fh = IO::String->new($str);
        my $old_fh = select($str_fh);

		my $retval;
        $x33eels::WebTextGateway::Common::Error = "";
		
		eval
		{
			$retval = &$send_sub($session, $message, $recipient, $credential3, $credential4);
		};

        select($old_fh) if defined $old_fh;

        if ($str && $str ne "")
        {
            $r->log_rerror(Apache2::Log::LOG_MARK, Apache2::Const::LOG_DEBUG, APR::Const::SUCCESS, "Module said: '$str'");
        }

		if (!$retval || $!)
		{
            my $err = $x33eels::WebTextGateway::Common::Error || $@ || $!;
			$r->log_reason($provider->{"id"}. ": Sending Failed: '" . $err . "'");

			if ($has_sent > 0)
			{
				return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_SENDING_FAILED_SOME, $err);
			}
			else
			{
				return die_with_message(x33eels::WebTextGateway::Common::RESULT_CODE_SENDING_FAILED_ALL, $err);
			}
		}

		$has_sent++;
	}

	$r->log_rerror(Apache2::Log::LOG_MARK, Apache2::Const::LOG_DEBUG, APR::Const::SUCCESS,
		"Message sent successfully to $has_sent recipient(s) using provider '" . $provider->{"id"} . "'");

	print "<response>\n";
	print "\t<result code=\"" . x33eels::WebTextGateway::Common::RESULT_CODE_SUCCESS . "\">" . x33eels::WebTextGateway::Common::RESULT_MESSAGE_SUCCESS . "</result>\n";
	print "\t<body>Message Sent!</body>\n";
	print "</response>\n";

	return Apache2::Const::OK;
}

sub get_provider
{
	my $provider_name = shift;

    $provider_name = lc($provider_name);

	my $providers = x33eels::WebTextGateway::Common::get_providers();

	if ($providers->{$provider_name})
	{
		return $providers->{$provider_name};
	}

	return 0;
}

sub check_api_key
{
	my $api_key = shift;

	my @valid_api_keys = x33eels::WebTextGateway::Common::get_valid_api_keys();

	for my $valid_api_key (@valid_api_keys)
	{
		if (lc($api_key) eq lc($valid_api_key))
		{
			return 1;
		}
	}
	
	return 0;
}

sub die_with_message
{
	my $code = shift;
	my $message = shift;

	if (!$message || $message eq "")
	{
		$message = "Error $code";
	}

    $message =~ s/</&lt;/g;
    $message =~ s/>/&gt;/g;
    $message =~ s/&/&amp;/g;

	print "<response>\n";
	print "\t<result code=\"" . $code . "\">" . x33eels::WebTextGateway::Common::RESULT_MESSAGE_ERROR . "</result>\n";
	print "\t<body>$message</body>\n";
	print "</response>\n";

	return Apache2::Const::OK;
}

1;

