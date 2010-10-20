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

    sub (HEAD) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->headers_in($req->headers);
      my $graph;
      if (my $g = $req->param('graph')) {
        $graph = $g;
      } else {
        $graph = $req->uri;
      }
      return $hb->head_response($graph)->finalize;
    },

    sub (GET) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->headers_in($req->headers);
      my $graph;
      if (my $g = $req->param('graph')) {
        $graph = $g;
      } else {
        $graph = $req->uri;
      }
      return $hb->get_response($graph)->finalize;
    },

    sub (DELETE) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->headers_in($req->headers);
      my $graph;
      if (my $g = $req->param('graph')) {
        $graph = $g;
      } else {
        $graph = $req->uri;
      }
      return $hb->delete_response($graph)->finalize;
    },

    sub (PUT) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      my $io = $req->input;
      my $putmodel = RDF::Trine::Model->temporary_model;
      my $parser;
      if (my $type = $req->header( 'Content-Type' )) {
        my $pclass = RDF::Trine::Parser->parser_by_media_type( $type );
        $parser = $pclass->new();
      }
      unless ($parser) { # This is underspecified
        $parser = RDF::Trine::Parser->new('rdfxml');
      }
      my $content	= '';
      my $read		= 0;
      while (1) {
      	my $r = $io->read($content, 1024, $read);
      	$read += $r;
      	last unless $r;
      }
      my $graph;
      if (my $g = $req->param('graph')) {
        $graph = $g;
      } else {
        $graph = $req->uri;
      }
      $parser->parse_into_model( $graph, $content, $putmodel );
      $hb->headers_in($req->headers);
      
      return $hb->put_response($graph, $putmodel)->finalize;
    },

    sub (POST) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      my $io = $req->input;
      my $putmodel = RDF::Trine::Model->temporary_model;
      my $parser;
      if (my $type = $req->header( 'Content-Type' )) {
        my $pclass = RDF::Trine::Parser->parser_by_media_type( $type );
        $parser = $pclass->new();
      }
      unless ($parser) { # This is underspecified
        $parser = RDF::Trine::Parser->new('rdfxml');
      }
      my $content	= '';
      my $read		= 0;
      while (1) {
      	my $r = $io->read($content, 1024, $read);
      	$read += $r;
      	last unless $r;
      }
      my $graph;
      if (my $g = $req->param('graph')) {
        $graph = $g;
      } else {
        $graph = $req->uri;
      }
      $parser->parse_into_model( $graph, $content, $putmodel );
      $hb->headers_in($req->headers);
      
      return $hb->post_response($graph, $putmodel)->finalize;
    },

    sub () {
      [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
    }
  };
}

RDF::Query::HTTPBindings::PlackServer->run_if_script;
