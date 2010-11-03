#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use Test::WWW::Mechanize::PSGI;

use RDF::Trine::Serializer::RDFXML;
use RDF::Trine::Serializer::Turtle;

BEGIN { require 'script/rdf_query_httpbindings.psgi'; }

my $serializer = RDF::Trine::Serializer::RDFXML->new;

my $base_uri = 'http://localhost:5000';

my $mech = Test::WWW::Mechanize::PSGI->new(app => RDF::Query::HTTPBindings::PlackServer->as_psgi_app);

my $uri1 = URI->new('http://localhost:5000/graphs/g1');
isa_ok($uri1, 'URI', "URI 1 object OK");

my $uri2 = URI->new('http://localhost:5000/graphs/g3');
isa_ok($uri2, 'URI', "URI 2 object OK");

diag "HEAD request";


$mech->head($uri1);
is($mech->status, 200, "Returns 200");
$mech->content_is('', 'No content');

$mech->head($uri2);
is($mech->status, 404, "Returns 404");
$mech->content_is('', 'No content');

diag "GET request";


$mech->get($uri1);
is($mech->status, 200, "Returns 200");
$mech->content_contains('This is a test', 'Test string found.');

is($mech->content_type, 'text/turtle', 'Correct content type');

$mech->get($uri2);
is($mech->status, 404, "Returns 404");

diag 'POST request';

$mech->post($uri1);
is($mech->status, 204, "POSTing no model gives 204");
$mech->content_is('', 'No content');

$mech->post($uri1, Content => 'Errrr');
is($mech->status, 415, "POSTing rubbish gives 415");

{
  my $inputmodel = RDF::Trine::Model->temporary_model;
  $inputmodel->add_statement(RDF::Trine::Statement->new(
			      RDF::Trine::Node::Resource->new('/foo', $base_uri),
			      RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
			      RDF::Trine::Node::Literal->new('DAHUT')));

  my $rdfxml = $serializer->serialize_model_to_string($inputmodel);
  $mech->post($uri1,
	      'Content-Type' => 'text/turtle',
	      Content => $rdfxml);
 TODO: {
    local $TODO = "Need 400 error messages";
    is($mech->status, 400, "POSTing RDF/XML with Turtle type gives 400");
  }
  $mech->post($uri1,
	      'Content-Type' => 'application/rdf+xml',
	      Content => $rdfxml);
  is($mech->status, 204, "POSTing a model gives 204");
  $mech->content_is('', 'No content');
}

$mech->get($uri1); # Check that we get what we posted.
is($mech->status, 200, "Returns 200");
$mech->content_contains('DAHUT', 'DAHUT test string found.');

{
  my $inputmodel = RDF::Trine::Model->temporary_model;
  $inputmodel->add_statement(RDF::Trine::Statement->new(
			      RDF::Trine::Node::Resource->new('/baz', $base_uri),
			      RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
			      RDF::Trine::Node::Literal->new('DAHUUUUUUT')));

  my $tserializer = RDF::Trine::Serializer::Turtle->new;
  my $turtle = $tserializer->serialize_model_to_string($inputmodel);
  $mech->post($uri1, Content => $turtle);

  is($mech->status, 415, "POSTing Turtle with no content-type gives 415");
  $mech->content_contains('Unsupported Content Type', 'Unsupported Content Type');

  $mech->post($uri1,
	      'Content-Type' => 'text/turtle',
	      Content => $turtle);
  is($mech->status, 204, "POSTing Turtle with correct content-type gives 204");
  $mech->content_is('', 'No content');
}

$mech->get($uri1); # Check that we get what we posted.
is($mech->status, 200, "Returns 200");
$mech->content_contains('DAHUUUUUUT', 'DAHUUUUUUT test string found.');


diag 'PUT request';

$mech->put($uri2);
is($mech->status, 201, "PUTting no model gives 201");
$mech->content_is('', 'No content');

 TODO: {
    local $TODO = "Need 415 error messages";
    $mech->put($uri2, Content => 'Errrr');
    is($mech->status, 415, "PUTting rubbish gives 415");
  }

{
  my $inputmodel = RDF::Trine::Model->temporary_model;
  $inputmodel->add_statement(RDF::Trine::Statement->new(
			      RDF::Trine::Node::Resource->new('/bar', $base_uri),
			      RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
			      RDF::Trine::Node::Literal->new('DAAAHUUUUT')));
  $mech->put($uri2, Content => $serializer->serialize_model_to_string($inputmodel));
  is($mech->status, 201, "PUTting a model gives 201");
  $mech->content_is('', 'No content');
  is($mech->res->header('Location'), $uri2, "Should return a Location to the same URI");
}

$mech->get($uri2); # Check that we get what we putted.
is($mech->status, 200, "Returns 200");
$mech->content_contains('DAAAHUUUUT', 'PUT test string refound');

diag 'DELETE request';

use HTTP::Request;
{
  my $request = HTTP::Request->new(DELETE => $uri2);
  $mech->request($request);
  is($mech->status, 204, "DELETing a graph gives 204");
  $mech->content_is('', 'No content');
}

$mech->get($uri2);
is($mech->status, 404, "Getting DELETEd graph returns 404");


diag "Unsupported FOOBAR request";
{
  my $request = HTTP::Request->new(FOOBAR => $uri1);
  $mech->request($request);
  is($mech->status, 405, "Returns 405");
  $mech->content_is('Method not allowed', 'Correct error message');
}

done_testing();
