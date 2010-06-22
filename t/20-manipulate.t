
use strict;
use Test::More;#  tests => 17;
use Test::Moose;
use Test::Exception;
use URI;
use HTTP::Headers;
use FindBin qw($Bin);

BEGIN {
  use_ok 'RDF::Query::HTTPBindings';
  use_ok 'RDF::Trine::Model';
}

my $file = $Bin . '/data/basic.trig';

my $parser     = RDF::Trine::Parser->new( 'trig' );
my $store = RDF::Trine::Store::Memory->new();
my $model = RDF::Trine::Model->new($store);
my $base_uri = 'http://localhost:5000';
$parser->parse_file_into_model( $base_uri, $file, $model );

my $hb = RDF::Query::HTTPBindings->new(model => $model);


my $uri_string = 'http://localhost:5000/graphs/g1';
my $uri = URI->new($uri_string);
ok($uri, "URI object OK");


my $get = $hb->get_response($uri);
isa_ok($get, 'Plack::Response', 'get_response returns');

is($get->code, 200, "Getting a graph OK");
diag ($get->body);


isa_ok($hb->put_response($uri), 'Plack::Response', 'put_response returns');
isa_ok($hb->post_response($uri), 'Plack::Response', 'post_response returns');
isa_ok($hb->delete_response($uri), 'Plack::Response', 'delete_response returns');


done_testing;
