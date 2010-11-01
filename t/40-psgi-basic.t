#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # tests => 28 ;
use Test::WWW::Mechanize::PSGI;

#use Plack::Request;
#use RDF::Trine::Parser;
#use RDF::LinkedData;
BEGIN { require 'script/rdf_query_httpbindings.psgi'; }

my $mech = Test::WWW::Mechanize::PSGI->new(app => RDF::Query::HTTPBindings::PlackServer->as_psgi_app);

my $uri1 = URI->new('http://localhost:5000/graphs/g1');
isa_ok($uri1, 'URI', "URI 1 object OK");

my $uri2 = URI->new('http://localhost:5000/graphs/g3');
isa_ok($uri2, 'URI', "URI 2 object OK");

diag "HEAD request";


$mech->head($uri1);
is($mech->status, 200, "Returns 200");
$mech->content_is('', 'No content');

#is($head->content_type, 'text/turtle', 'Correct content type');

$mech->head($uri2);
is($mech->status, 404, "Returns 404");
$mech->content_is('', 'No content');


done_testing();
