use strict;
use warnings;

use Test::More tests => 16;

use URI::FromHash qw( uri uri_object );

{
    my $uri = uri_object( scheme => 'http',
                          host   => 'example.com',
                        );
    isa_ok( $uri, 'URI', 'uri_object() returns a URI object' );
    is( $uri->scheme, 'http', 'scheme is http' );
}

{
    my $uri = uri( scheme => 'http',
                   host   => 'example.com',
                 );
    is( $uri, 'http://example.com/', 'uri is http://example.com/' );
}

{
    my $uri = uri( scheme => 'http',
                   host   => 'example.com',
                   path   => '/foo/bar',
                 );
    is( $uri, 'http://example.com/foo/bar', 'uri is http://example.com/foo/bar' );
}

{
    my $uri = uri( scheme => 'http',
                   host   => 'example.com',
                   query  => { a => 1, b => 'foo' },
                 );
    like( $uri, qr{^http://example.com\?}, 'uri starts with http://example.com?' );
    like( $uri, qr{\?(?:a=1;b=foo)|(?:b=foo;a=1)}, 'contains expected query elements' );
}

{
    my $uri = uri( scheme => 'http',
                   host   => 'example.com',
                   query  => { a => 1, b => 'foo' },
                   query_separator => '|',
                 );
    like( $uri, qr{^http://example.com\?}, 'uri starts with http://example.com?' );
    like( $uri, qr{\?(?:a=1|b=foo)|(?:b=foo|a=1)}, 'contains expected query elements' );
}

{
    my $uri = uri( scheme   => 'http',
                   host     => 'example.com',
                   fragment => 'frag',
                 );
    is( $uri, 'http://example.com/#frag', 'uri is http://example.com/#frag' );
}

{
    my $uri = uri( scheme   => 'http',
                   host     => 'example.com',
                   username => 'bubba',
                   password => 'secret',
                 );
    is( $uri, 'http://bubba:secret@example.com/',
        'uri is http://bubba:secret@example.com/' );
}

{
    my $uri = uri( scheme => 'http',
                   host   => 'example.com',
                   port   => 8080
                 );
    is( $uri, 'http://example.com:8080/',
        'uri is http://example.com:8080/' );
}

{
    my $uri = uri( scheme => 'http',
                   host   => 'example.com',
                   query  => { a => [ 1, 2 ] },
                 );
    like( $uri, qr{\?(?:a=1;a=2)|(?:a=2;a=1)}, 'contains expected query elements' );
}

{
    my $uri = uri( path  => '/my/path',
                   query => { foo => 'seven' },
                 );
    is( $uri, '/my/path?foo=seven',
        'uri is /my/path?foo=seven' );
}

{
    my $uri = uri( scheme   => 'http',
                   host     => 'example.com',
                   username => 'bubba',
                 );
    is( $uri, 'http://bubba:@example.com/',
        'uri is http://bubba:@example.com/' );
}

{
    my $uri = uri( scheme   => 'http',
                   host     => 'example.com',
                   username => 'bubba',
                 );
    is( $uri, 'http://bubba:@example.com/',
        'uri is http://bubba:@example.com/' );
}

{
    eval { uri( port => 70, username => 'test' ) };
    like( $@, qr/required parameters/,
          'got an error when none of the required params were given' );
}
