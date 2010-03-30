package x33eels::WebTextGateway::ProviderList;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

use Data::Dumper;
use x33eels::WebTextGateway::Common;

sub handler
{
	my $r = shift;

	$r->content_type("application/xml");

	print "<response>\n";
	print "\t<result code=\"" . x33eels::WebTextGateway::Common::RESULT_CODE_SUCCESS . "\">" . x33eels::WebTextGateway::Common::RESULT_MESSAGE_SUCCESS . "</result>\n";
	print "\t<body>\n";

	my $providers = x33eels::WebTextGateway::Common::get_providers();

	for my $provider_id ( keys %$providers )
	{
		#my %value = %{$value};

		#print Dumper($providers{$key});

		my $provider = $providers->{$provider_id};

		print "\t\t<provider ";
		print "id=\"" . $provider_id . "\" ";
		print "name=\"" . $provider->{"name"} . "\" ";
		print "credentials=\"" . $provider->{"credentials"} . "\" ";
		print "status=\"" . $provider->{"status"} . "\" ";
		print "/>\n";
	}

	print "\t</body>\n";
	print "</response>\n";

	return Apache2::Const::OK;
}

1;

