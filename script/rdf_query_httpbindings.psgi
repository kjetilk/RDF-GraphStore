#!/usr/bin/perl

use Web::Simple 'RDF::Query::HTTPBindings::PlackServer';
use RDF::Trine;
use Config::JFDI;
use RDF::Query::HTTPBindings;
use Plack::Request;
use Carp qw(confess);

my $config;
BEGIN {
  $config = Config::JFDI->open( name => "RDF::Query::HTTPBindings") || confess "Couldn't find config";
}

{
  package RDF::Query::HTTPBindings::PlackServer;

  my $store = RDF::Trine::Store->new_with_config($config);
  my $model = RDF::Trine::Model->new($store);

  my $hb = RDF::Query::HTTPBindings->new(model => $model);
  use Data::Dumper;
  
  dispatch {
 #   sub (GET ?graph=) {
     # die Dumper(@_);
  #  },

    sub (GET) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->headers_in($req->headers);
      return $hb->get_response($req->uri)->finalize;
    },

    sub () {
      [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
    }
  };
}




RDF::Query::HTTPBindings::PlackServer->run_if_script;
