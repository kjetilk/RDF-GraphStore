
use strict;
use Test::More  tests => 6;
use Test::Moose;
use Test::RDF;
use URI;
use HTTP::Headers;
use FindBin qw($Bin);
use utf8;


BEGIN {
  use_ok 'RDF::GraphStore';
  use_ok 'RDF::Trine::Model';
}

my $file = $Bin . '/data/basic.trig';

my $parser     = RDF::Trine::Parser->new( 'trig' );
my $store = RDF::Trine::Store::Memory->new();
my $model = RDF::Trine::Model->new($store);
my $base_uri = 'http://localhost:5000';
$parser->parse_file_into_model( $base_uri, $file, $model );

my $hb = RDF::GraphStore->new(model => $model);


my $uri_string = 'http://localhost:5000/graphs/g2';
my $uri = URI->new($uri_string);
ok($uri, "URI object OK");

$hb->graph_uri($uri);
my $get = $hb->get_response;
isa_ok($get, 'Plack::Response', 'get_response returns');

is($get->code, 200, "Getting a graph OK");

my $tmpmodel = RDF::Trine::Model->temporary_model;
my $tparser     = RDF::Trine::Parser->new( 'turtle' );
$tparser->parse_into_model($uri, $get->body, $tmpmodel);

has_literal("Blåbærsyltetøy", 'no', undef, $tmpmodel, 'Test string with Norwegian characters found');

done_testing;
