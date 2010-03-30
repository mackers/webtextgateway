ServerName webtext-gw.33eels.com

<VirtualHost *>

	SSLEngine on
	SSLCertificateFile /etc/apache2/apache.pem

        ServerAdmin webmaster@33eels.com
        ServerName webtext-gw.33eels.com
        ServerAlias vesuvius.33eels.com
        ServerAlias webtext-gw.33eels.com.dev.33eels.com

        DocumentRoot /var/www/hosts/webtext-gw.33eels.com/htdocs/

        ErrorLog /var/www/hosts/webtext-gw.33eels.com/log/error.log
        LogLevel info
        CustomLog /var/www/hosts/webtext-gw.33eels.com/log/access.log combined
        ServerSignature On

        PerlRequire /var/www/hosts/webtext-gw.33eels.com/modperl/startup.pl
	#SetEnv LANG en_US.UTF-8
	#PerlSwitches -CIOEioA

        <Location /webtext/api/1.0/ping>
                SetHandler perl-script
                PerlResponseHandler x33eels::WebTextGateway::Ping
        </Location>

        <Location /webtext/api/1.0/send>
                SetHandler perl-script
                PerlResponseHandler x33eels::WebTextGateway::Send
        </Location>

        <Location /webtext/api/1.0/provider_list>
                SetHandler perl-script
                PerlResponseHandler x33eels::WebTextGateway::ProviderList
        </Location>

</VirtualHost>


