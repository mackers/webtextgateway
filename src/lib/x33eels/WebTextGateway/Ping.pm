package x33eels::WebTextGateway::Ping;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

use x33eels::WebTextGateway::Common;

sub handler
{
	my $r = shift;

	$r->content_type("application/xml");

	print "<response>\n";
	print "\t<result code=\"" . x33eels::WebTextGateway::Common::RESULT_CODE_SUCCESS . "\">" . x33eels::WebTextGateway::Common::RESULT_MESSAGE_SUCCESS . "</result>\n";
	print "\t<body>pong</body>\n";
	print "</response>\n";

	return Apache2::Const::OK;
}

1;

