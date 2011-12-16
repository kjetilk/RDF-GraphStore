#!/usr/bin/perl

use RDF::Trine;
use Config::JFDI;
use RDF::GraphStore;
use Plack::Request;
use Carp qw(confess);
use URI;

my $config;
BEGIN {
  $config = Config::JFDI->open( name => "RDF::GraphStore") || confess "Couldn't find config";
}

{
  package RDF::GraphStore::PlackServer;

  my $store = RDF::Trine::Store->new_with_config($config);
  my $model = RDF::Trine::Model->new($store);

  my $hb = RDF::GraphStore->new(model => $model);
  use Data::Dumper;
  
  dispatch {
    sub (HEAD + ?graph=) {
      my ($self, $graph) = @_;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $graph);
      return $hb->head_response->finalize;
    },

    sub (HEAD) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $req->uri);
      return $hb->head_response->finalize;
    },

    sub (GET + ?graph=) {
      my ($self, $graph) = @_;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $graph);
      return $hb->get_response->finalize;
    },

    sub (GET) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $req->uri);
      return $hb->get_response->finalize;
    },


    sub (DELETE + ?graph=) {
      my ($self, $graph) = @_;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $graph);
      return $hb->delete_response->finalize;
    },

    sub (DELETE) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $req->uri);
      return $hb->delete_response->finalize;
    },


    sub (PUT + ?graph=) {
      my ($self, $graph) = @_;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $graph);
      return $hb->put_response($hb->payload_model($req))->finalize;
    },

    sub (PUT) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $req->uri);
      return $hb->put_response($hb->payload_model($req))->finalize;
    },

    sub (POST + ?graph=) {
      my ($self, $graph) = @_;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $graph);
      return $hb->post_response($hb->payload_model($req))->finalize;
    },

    sub (POST) {
      my $self = shift;
      my $req = Plack::Request->new($_[PSGI_ENV]);
      $hb->init($req->headers, $req->uri);
      return $hb->post_response($hb->payload_model($req))->finalize;
    },

    sub () {
      [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
    }
  };
}

RDF::GraphStore::PlackServer->run_if_script;
