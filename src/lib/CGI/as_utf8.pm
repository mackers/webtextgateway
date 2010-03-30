package CGI::as_utf8;

BEGIN
{
    use strict;
    use warnings;
    use CGI;
    use Encode;

    {
        no warnings 'redefine';
        my $param_org = \&CGI::param;

        my $might_decode = sub {
            my $p = shift;
            # make sure upload() filehandles are not modified
            return ( !$p || ( ref $p && fileno($p) ) )
                ? $p    
                : eval { decode_utf8($p) } || $p;
        };

        *CGI::param = sub {
            my $q = $_[0];    # assume object calls always
            my $p = $_[1];

            # setting a param goes through the original interface
            goto &$param_org if scalar @_ != 2;

            return wantarray
                ? map { $might_decode->($_) } $q->$param_org($p)
                : $might_decode->( $q->$param_org($p) );
            }
    }
}

1;

