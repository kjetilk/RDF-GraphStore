
use strict;
use Test::More  tests => 35;
use Test::Moose;
use Test::RDF;
use Test::Exception;
use URI;
use HTTP::Headers;
use HTTP::Request;
use FindBin qw($Bin);

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



my $uri1 = URI->new('http://localhost:5000/graphs/g1');
isa_ok($uri1, 'URI', "URI 1 object OK");

my $uri2 = URI->new('http://localhost:5000/graphs/g3');
isa_ok($uri2, 'URI', "URI 2 object OK");

note "GET request";
$hb->clear_response;
$hb->graph_uri($uri1);
my $get = $hb->get_response;
isa_ok($get, 'Plack::Response', 'get_response returns');

is($get->code, 200, "Getting a graph OK");
like($get->body, qr/"This is a test"\@en/, 'Test string found');
like($get->body, qr|<http://localhost:5000/foo> <http://xmlns.com/foaf/0.1/page> <http://en.wikipedia.org/wiki/Foo> ;\s+<http://www.w3.org/2000/01/rdf-schema#label> "This is a test"\@en .\s+<http://localhost:5000/bar/baz/bing> <http://www.w3.org/2000/01/rdf-schema#label> "Testing with longer URI."\@en .|, "All content matches");

is($get->content_type, 'text/turtle', 'Correct content type');

$hb->clear_response;
$hb->graph_uri($uri2);
my $get2 = $hb->get_response;
isa_ok($get2, 'Plack::Response', 'get_response returns');

is($get2->code, 404, "Getting a non-existent graph returns 404");

note 'POST request';

my $h = HTTP::Headers->new;
$h->header('Content-Type' => 'text/turtle');

{
  $hb->clear_response;
  $hb->graph_uri($uri1);
  my $r = HTTP::Request->new('POST', $hb->graph_uri, $h, '');
  my $post = $hb->post_response($r);
  isa_ok($post, 'Plack::Response', 'post_response returns');
  is($post->code, 204, "POSTing no model gives 204");
  is(length($post->body), 0, "No content returned");
}

{
  $hb->clear_response;
  $hb->graph_uri($uri1);

  my $content = "<$base_uri/foo> <http://xmlns.com/foaf/0.1/name> \"DAHUT\" .";
  $h->header('Content-Length' => length($content));
  my $r = HTTP::Request->new('POST', $hb->graph_uri, $h, $content);
  my $post = $hb->post_response($r);
  isa_ok($post, 'Plack::Response', 'post_response returns');
  is($post->code, 204, "POSTing a model gives 204");
  is(length($post->body), 0, "No content returned");

#  $hb->clear_response;
  my $get_after_post = $hb->get_response;
  isa_ok($get_after_post, 'Plack::Response', 'get_response returns');

  is($get_after_post->code, 200, "Getting POSTed graph OK");
  like($get_after_post->body, qr/DAHUT/, 'Posted test string refound');
  like($get_after_post->body, qr|<http://localhost:5000/foo>\s+<http://xmlns.com/foaf/0.1/name>\s+"DAHUT"\s+;\s+<http://xmlns.com/foaf/0.1/page>\s+<http://en.wikipedia.org/wiki/Foo>\s+;\s+<http://www.w3.org/2000/01/rdf-schema#label>\s+"This is a test"\@en\s+.\s+<http://localhost:5000/bar/baz/bing>\s+<http://www.w3.org/2000/01/rdf-schema#label>\s+"Testing with longer URI."\@en\s+.|, "All content matches");
}

note 'PUT request';

{
  $hb->clear_response;
  $hb->graph_uri($uri2);
  my $r = HTTP::Request->new('PUT', $hb->graph_uri, $h, '');
  my $put = $hb->put_response($r);
  isa_ok($put, 'Plack::Response', 'put_response returns');
  is($put->code, 204, "PUTing nothing gives 204");
 TODO: {
    local $TODO = 'Ask WG if this should have a Location, since you cannot GET from it, or can you?';
    is($put->location, $uri2, "Should return a Location to the same URI");
  }
}

{
  my $inputmodel = RDF::Trine::Model->temporary_model;
  my $content ="<$base_uri/bar> <http://xmlns.com/foaf/0.1/name> \"DAAAHUUUUT\" .";
  $h->header('Content-Length' => length($content));
  my $r = HTTP::Request->new('PUT', $hb->graph_uri, $h, $content);

  $hb->clear_response;
  $hb->graph_uri($uri2);
  my $put = $hb->put_response($r);
  isa_ok($put, 'Plack::Response', 'put_response returns');
  is($put->code, 201, "PUTing model gives 201");

  $hb->clear_response;
  my $get_after_put = $hb->get_response($uri2);
  isa_ok($get_after_put, 'Plack::Response', 'get_response returns');

  is($get_after_put->code, 200, "Getting PUT graph OK");
  like($get_after_put->body, qr/DAAAHUUUUT/, 'PUT test string refound');

}

note 'DELETE request';

{
  $hb->clear_response;
  $hb->graph_uri($uri2);
  my $delete = $hb->delete_response;
  isa_ok($delete, 'Plack::Response', 'delete_response returns');
  is($delete->code, 204, "DELETEing a model gives 204");

  $hb->clear_response;
  my $get_after_delete = $hb->get_response;
  isa_ok($get_after_delete, 'Plack::Response', 'get_response returns');
  is($get_after_delete->code, 404, "Getting DELETEd graph returns 404");
}

{
  $hb->clear_response;
  $hb->graph_uri($uri2);
  my $delete = $hb->delete_response($uri2);
  isa_ok($delete, 'Plack::Response', 'delete_response returns');
TODO: {
  local $TODO = 'I have to check if the URI exists and throw 404';

  is($delete->code, 404, "DELETEing a graph that doesn't exist gives 404");
}}

done_testing;
