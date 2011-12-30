#!/usr/bin/perl

use RDF::Trine;

use Config::JFDI;
use Plack::App::RDF::GraphStore;

use Carp qw(confess);
use URI;
use Plack::Builder;

my $config;
BEGIN {
	$config = Config::JFDI->open( name => "RDF::GraphStore") || confess "Couldn't find config";
}

use Data::Dumper;

warn Dumper($config);

my $graphstore = Plack::App::RDF::GraphStore->new();

$graphstore->configure($config);

my $rdf_graphstore = $graphstore->to_app;

builder {
	enable "Plack::Middleware::Head";
	enable "Plack::Middleware::ContentLength";
	$rdf_graphstore;
};
