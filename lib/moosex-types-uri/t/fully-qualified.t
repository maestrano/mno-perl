use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::URI 'Uri';

my $uri = URI->new("http://www.google.com");

ok(is_Uri($uri), 'is_Uri');

ok(Uri->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

# TODO: it would be nice to have this work *and* be able to keep our
# namespaces clean -- but it looks like we need to do this in MooseX::Types
# itself, by using Sub::Exporter::ForMethods.
ok(MooseX::Types::URI::Uri->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;
