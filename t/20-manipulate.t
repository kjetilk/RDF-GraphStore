
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



my $uri1 = URI->new('http://localhost:5000/graphs/g1');
ok($uri1, "URI 1 object OK");

my $uri2 = URI->new('http://localhost:5000/graphs/g3');
ok($uri2, "URI 2 object OK");

diag "GET request";
my $get = $hb->get_response($uri1);
isa_ok($get, 'Plack::Response', 'get_response returns');

is($get->code, 200, "Getting a graph OK");
like($get->body, qr/"This is a test"\@en/, 'Test string found');
like($get->body, qr|<http://localhost:5000/foo> <http://xmlns.com/foaf/0.1/page> <http://en.wikipedia.org/wiki/Foo> ;\s+<http://www.w3.org/2000/01/rdf-schema#label> "This is a test"\@en .\s+<http://localhost:5000/bar/baz/bing> <http://www.w3.org/2000/01/rdf-schema#label> "Testing with longer URI."\@en .|, "All content matches");

is($get->content_type, 'text/turtle', 'Correct content type');

my $get2 = $hb->get_response($uri2);
isa_ok($get2, 'Plack::Response', 'get_response returns');

is($get2->code, 404, "Getting a non-existent graph returns 404");

diag 'POST request';

{
  my $post = $hb->post_response($uri1);
  isa_ok($post, 'Plack::Response', 'post_response returns');
  is($post->code, 204, "POSTing no model gives 204");
  is(length($post->body), 0, "No content returned");
}

  my $inputmodel = RDF::Trine::Model->temporary_model;
  $inputmodel->add_statement(RDF::Trine::Statement->new(
			      RDF::Trine::Node::Resource->new('/foo', $base_uri),
			      RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
			      RDF::Trine::Node::Literal->new('DAHUT')));
  my $post = $hb->post_response($uri1, $inputmodel);
  isa_ok($post, 'Plack::Response', 'post_response returns');
  is($post->code, 204, "POSTing a model gives 204");
  is(length($post->body), 0, "No content returned");

  my $get_after_post = $hb->get_response($uri1);
  isa_ok($get_after_post, 'Plack::Response', 'get_response returns');

  is($get_after_post->code, 200, "Getting POSTed graph OK");
  like($get_after_post->body, qr/DAHUT/, 'Posted test string refound');
  like($get_after_post->body, qr|<http://localhost:5000/foo>\s+<http://xmlns.com/foaf/0.1/name>\s+"DAHUT"\s+;\s+<http://xmlns.com/foaf/0.1/page>\s+<http://en.wikipedia.org/wiki/Foo>\s+;\s+<http://www.w3.org/2000/01/rdf-schema#label>\s+"This is a test"\@en\s+.\s+<http://localhost:5000/bar/baz/bing>\s+<http://www.w3.org/2000/01/rdf-schema#label>\s+"Testing with longer URI."\@en\s+.|, "All content matches");

diag 'PUT request';

isa_ok($hb->put_response($uri2), 'Plack::Response', 'put_response returns');

diag 'DELETE request';

isa_ok($hb->delete_response($uri2), 'Plack::Response', 'delete_response returns');


done_testing;
