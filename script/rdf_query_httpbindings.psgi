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

    sub (DELETE) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      warn "deleting " . $req->uri;
      $hb->headers_in($req->headers);
      return $hb->delete_response($req->uri)->finalize;
    },

    sub (PUT) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      my $io = $req->input;
      my $putmodel = RDF::Trine::Model->temporary_model;
      my $parser;
      if (my $type = $req->header( 'Content-Type' )) {
        my $pclass = RDF::Trine::Parser->parsr_by_media_type( $type );
        $parser = $pclass->new();
      }
      unless ($parser) {
        $parser = RDF::Trine::Parser->new('rdfxml');
      }
      my $content	= '';
      my $read		= 0;
      while (1) {
      	my $r = $io->read($content, 1024, $read);
      	$read += $r;
      	last unless $r;
      }
      $parser->parse_into_model( $req->base, $content, $putmodel );
      $hb->headers_in($req->headers);
      
      return $hb->put_response($req->uri, $putmodel)->finalize;
    },

    sub (POST) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      my $io = $req->input;
      my $putmodel = RDF::Trine::Model->temporary_model;
      my $parser;
      if (my $type = $req->header( 'Content-Type' )) {
        my $pclass = RDF::Trine::Parser->parsr_by_media_type( $type );
        $parser = $pclass->new();
      }
      unless ($parser) {
        $parser = RDF::Trine::Parser->new('rdfxml');
      }
      my $content	= '';
      my $read		= 0;
      while (1) {
      	my $r = $io->read($content, 1024, $read);
      	$read += $r;
      	last unless $r;
      }
      $parser->parse_into_model( $req->base, $content, $putmodel );
      $hb->headers_in($req->headers);
      
      return $hb->post_response($req->uri, $putmodel)->finalize;
    },

    sub () {
      [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
    }
  };
}

RDF::Query::HTTPBindings::PlackServer->run_if_script;
