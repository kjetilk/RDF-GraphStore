use Test::More tests => 19;
use Test::Moose;
use Test::Exception;
use URI;
use HTTP::Headers;

BEGIN {
  use_ok 'RDF::Query::HTTPBindings';
}

my $hb = RDF::Query::HTTPBindings->new(model => RDF::Trine::Model->temporary_model);

my $uri_string = 'http://localhost:5000/foo';
my $uri = URI->new($uri_string);
ok($uri, "URI object OK");

isa_ok($hb, 'RDF::Query::HTTPBindings');
has_attribute_ok($hb, 'model');
has_attribute_ok($hb, 'response');
has_attribute_ok($hb, 'headers_in');
has_attribute_ok($hb, 'graph_uri');


{
  dies_ok{$hb->head_response} 'head_response dies';
  dies_ok{$hb->get_response} 'get_response dies';
  dies_ok{$hb->put_response} 'put_response dies';
  dies_ok{$hb->post_response} 'post_response dies';
  dies_ok{$hb->delete_response} 'delete_response dies';
}


ok($hb->graph_uri($uri), "Can set URI to URI object");
isa_ok($hb->graph_uri, 'URI');

{
  isa_ok($hb->head_response, 'Plack::Response', 'head_response returns');
  isa_ok($hb->get_response, 'Plack::Response', 'get_response returns');
  isa_ok($hb->put_response, 'Plack::Response', 'put_response returns');
  isa_ok($hb->post_response, 'Plack::Response', 'post_response returns');
  isa_ok($hb->delete_response, 'Plack::Response', 'delete_response returns');
}


done_testing;
