#!/usr/bin/perl

use RDF::Trine;

use Config::JFDI;
use Plack::Middleware::GraphStore;

use Carp qw(confess);
use URI;
use Plack::Builder;

my $config;
BEGIN {
	$config = Config::JFDI->open( name => "RDF::GraphStore") || confess "Couldn't find config";
}

use Data::Dumper;

warn Dumper($config);
my $rdf_graphstore = sub { return ['', '', '']};
builder {
	enable "Plack::Middleware::GraphStore", (config => $config);
	$rdf_graphstore;
};
