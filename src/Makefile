test:
	sudo apache2ctl restart && curl --verbose -k http://webtext-gw.33eels.com.dev.33eels.com/webtext/api/1.0/send -d recipient=%2B34636685421 -d provider=dummy -d message=ook -d credential1=0863608308 -d credential2=promptfor1 -d credential3=%2B34636685421 -d api_key=9019b3509f83210d5fbf59f70ef7f25a

update-o2sms:
	svn export --force svn+ssh://svn.33eels.com/var/svn/testgen4web-perl/main/lib/TestGen4Web/ lib/TestGen4Web/
	svn export --force svn+ssh://svn.33eels.com/var/svn/o2sms/main/o2sms3/lib/WWW/SMS/IE/ lib/WWW/SMS/IE/

update-from-perl-root:
	chmod -R u+w lib/*
	cp -r ../perl_src/install_root/share/perl/5.10.0/* lib/

install-cpan-dependencies:
	cpan -i  WWW::SMS::IE::iesms
	cpan -i  WWW::SMS::IE::o2sms
	cpan -i  WWW::SMS::IE::vodasms
	cpan -i  WWW::SMS::IE::meteorsms
	cpan -i  SMS::Send
	cpan -i  SMS::Send::Clickatell
	cpan -i  SMS::Send::AQL
	cpan -i  SMS::Send::DE::MeinBMW
	cpan -i  SMS::Send::US::Ipipi
	cpan -i  SMS::Send::US::Verizon
	cpan -i  SMS::Send::US::TMobile
	cpan -i  SMS::Send::AU::MyVodafone
	cpan -i  SMS::Send::TW::emome
	cpan -i  SMS::Send::TW::ShareSMS
	cpan -i  SMS::Send::TW::PChome
	cpan -i  SMS::Send::TW::HiAir
	cpan -i  SMS::Send::NL::MyVodafone
	cpan -i  SMS::Send::NL::Mollie
	cpan -i  SMS::Send::IS::Vit
	cpan -i  SMS::Send::IS::Vodafone
	#cpan -i  SMS::Send::US::SprintPCS
	cpan -i  SMS::Send::AT::SmsAt
	cpan -i  Date::Manip
	cpan -i  WWW::SMS
	cpan -i  Net::SMS::ASPSMS
	cpan -i  Net::SMS::2Way
	cpan -i  Net::SMS::MyTMN
	cpan -i  Net::SMS::MessageNet
	cpan -i  Net::SMS::Optimus
	#cpan -i  Net::SMS::VoipBuster
	cpan -i  SMS::Claro
	cpan -i  Net::SMS::Clickatell
	cpan -i  Net::Clickatell
	cpan -i  Frontier::Client

