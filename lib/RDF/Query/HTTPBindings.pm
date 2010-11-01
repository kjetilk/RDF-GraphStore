package RDF::Query::HTTPBindings;

use Moose;
use namespace::autoclean;

use RDF::Query 2.9;
use RDF::Trine 0.130;
use RDF::Trine::Model;
use RDF::Trine::Iterator;
use RDF::Trine::Serializer;
use RDF::Trine::Serializer::NTriples;

use Plack::Response;
use URI;
use URI::Escape;
use Encode;
use Digest::MD5 qw(md5_hex);


=head1 NAME

RDF::Query::HTTPBindings - SPARQL 1.1 HTTP Bindings

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



# =head1 SYNOPSIS

=head1 DESCRIPTION

This module attempts to track the SPARQL 1.1. HTTP Bindings document,
currently mostly as a discussion item.

This first release contains the queries specified in the
specification, but be warned that this is not the most efficient way
to implement the specification, and is subject to change in later
releases.

The SPARQL 1.1 HTTP bindings document, which can be found at
L<http://www.w3.org/TR/sparql11-http-rdf-update/> specifies how RDF
graphs can be updated with using four HTTP verbs in a RESTful
manner. This module is first and foremost intended as a discussion
item implementation of the proposed protocol.



=head1 METHODS

=head2 model

The model we're working on.

=cut

has 'model' => (is => 'rw', isa => 'RDF::Trine::Model');


=head2 headers_in ( [ $headers ] )

Returns the L<HTTP::Headers> object if it exists or sets it if a L<HTTP::Headers> object is given as parameter.

=cut

has headers_in => ( is => 'rw', isa => 'HTTP::Headers', builder => '_build_headers_in');

sub _build_headers_in {
    return HTTP::Headers->new() ;
}


=head2 graph_uri ($uri)

Returns the L<HTTP::Headers> object if it exists or sets it if a L<HTTP::Headers> object is given as parameter.

=head2 has_graph_uri

Returns true if the graph_uri has been set.

=cut

has graph_uri => ( is => 'rw', isa => 'URI',
		   trigger => \&_set_graph_uri, predicate => 'has_graph_uri');

sub _set_graph_uri {
  my $uri = shift;
  confess 'No URI given' unless (defined($uri));
  # TODO: Is this sufficient input sanatizing?
  $uri = uri_escape($uri, ">");
  return $uri;
}

=head2 head_response()

What to do with a HEAD request. Takes a URI object or a simple string
as argument. Returns a Plack::Response object.

=cut

sub head_response {
  return _head_and_get_response(@_, 0);
}


=head2 get_response

What to do with a GET request. Takes a URI object or a simple string
as argument. Returns a Plack::Response object.

=cut

sub get_response {
  return _head_and_get_response(@_, 1);
}

# Do the actual work, with an additional boolean that should be true if we do a GET
sub _head_and_get_response {
  my $self = shift;
  confess('No graph URI given') unless $self->has_graph_uri;
  my $uri = $self->graph_uri;
  my $get = shift;
  my $res = Plack::Response->new;
  
  my $etag = $self->_etag($uri);
  if (my $code = $self->_check_etag($uri, $etag)) {
  	$res->status($code);
  	return $res;
  }
  
  my $sparql = "CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <$uri> { ?s ?p ?o } }";
  my $query = RDF::Query->new($sparql);
  my $iterator = $query->execute($self->model);
  # Need to serialize first to find the number of returned triples
  my ($ct, $serializer) = RDF::Trine::Serializer->negotiate('request_headers' => $self->headers_in);
  my $output = $serializer->serialize_iterator_to_string($iterator);

  if (defined($iterator) && ($iterator->is_graph) && ($iterator->count > 0)) {
    my $body = encode_utf8($output);
    if ($get) {
      $res->body($body);
    }
    $res->content_type($ct);
    $res->content_length(bytes::length($body));
    $res->status(200);
    if (defined($etag)) {
      $res->headers->header( ETag => $etag );
    }
  } else {
    $res->status(404);
    $res->content_type('text/plain');
    if ($get) {
      $res->body('Graph not found');
    }
  }
  return $res;
}

=head2 put_response

What to do with a PUT request. Returns a Plack::Response object.

=cut

sub put_response {
  my $self = shift;
  confess('No graph URI given') unless $self->has_graph_uri;
  my $uri = $self->graph_uri;
  my $new_model = shift;
  my $res = Plack::Response->new;
  my $sparql = "DROP SILENT GRAPH <$uri>;\n";
  if (defined($new_model) && $new_model->isa('RDF::Trine::Model')) {
    # TODO: How do we escape the payload for security?
    $sparql .= "INSERT DATA { GRAPH <$uri> {\n\t" . _serialize_payload( $new_model ) . '} }';
    $res->location($uri);
  }
  my $query = RDF::Query->new($sparql, { update => 1 }) || confess (RDF::Query->error);
  $query->execute($self->model); # TODO: What could go wrong here and how do we deal with it?
  $res->code(201);
  return $res;
}


=head2 post_response

What to do with a POST request. Returns a Plack::Response object.

=cut

sub post_response {
  my $self = shift;
  confess('No graph URI given') unless $self->has_graph_uri;
  my $uri = $self->graph_uri;
  my $add_model = shift;
  my $res = Plack::Response->new;
  unless (defined($add_model) && $add_model->isa('RDF::Trine::Model')) {
    # Simply return if no payload. TODO: Ask WG about this
    $res->code(204);
    return $res;
  }
  # TODO: How do we escape the payload for security?
  my $sparql = "INSERT DATA { GRAPH <$uri> {\n\t" . _serialize_payload($add_model) . '} }';
  my $query = RDF::Query->new($sparql, { update => 1 }) || confess (RDF::Query->error);
  $query->execute($self->model); # TODO: What could go wrong here and how do we deal with it?
  $res->code(204);
  # TODO: Support the "201 + Location" scenario
  return $res;
}

=head2 delete_response

What to do with a DELETE request. Returns a Plack::Response object.

=cut

sub delete_response {
  my $self = shift;
  confess('No graph URI given') unless $self->has_graph_uri;
  my $uri = $self->graph_uri;
  my $res = Plack::Response->new;
  my $sparql = "DROP GRAPH <$uri>";
  my $query = RDF::Query->new($sparql, { update => 1 }) || confess (RDF::Query->error);
  $query->execute($self->model); # TODO: What could go wrong here and how do we deal with it?
  $res->code(204);
  return $res;
}


=head2 payload_model ( $request )

Return a L<RDF::Trine::Model> with the triples from the payload.

=cut

sub payload_model {
  my ($self, $req) = @_;

  my $io = $req->input;
  my $model = RDF::Trine::Model->temporary_model;
  my $parser;
  if (my $type = $req->header( 'Content-Type' )) {
    my $pclass = RDF::Trine::Parser->parser_by_media_type( $type );
    if ($pclass) {
      $parser = $pclass->new();
    } # TODO: else return 415?
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

  $parser->parse_into_model( $self->graph_uri, $content, $model );

  return $model;
}

sub _serialize_payload {
  my $modify_model = shift;
  confess 'No model given' unless (defined($modify_model) && $modify_model->isa('RDF::Trine::Model'));
  my $serializer = RDF::Trine::Serializer::NTriples->new();
  return $serializer->serialize_model_to_string ( $modify_model );
}

sub _etag {
  my $self = shift;
  my $graph = shift;
  my $match = $self->headers_in->header('if-none-match') || '';
  my $type = $self->headers_in->header('Accept') || '';
  my $etag = md5_hex( join('#', $self->model->etag, $type, $graph) );
  return $etag;
}

sub _check_etag {
  my $self = shift;
  my $graph = shift;
  my $etag = shift;
  my $match = $self->headers_in->header('if-none-match') || '';
  if (length($match)) {
    if (defined($etag) and ($etag eq $match)) {
      return 304;
    }
  }
}

=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-query-httpbindings at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Query-HTTPBindings>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 FUTURE DIRECTIONS

The current implementation's main goal is to be close to the
specification, and thus it contains the query strings as given in the
specification. However, this is not the best way to implement this, as
a pure L<RDF::Trine> implementation is possible.

Once the specification is finalized, the plan is to create a
L<Moose::Role> with a default implementation that does this the most
efficient way, and leave the present implementation as an alternative
implementation for demonstration purposes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RDF::Query::HTTPBindings


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RDF-Query-HTTPBindings>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RDF-Query-HTTPBindings>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-Query-HTTPBindings>

=item * Search CPAN

L<http://search.cpan.org/dist/RDF-Query-HTTPBindings/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


__PACKAGE__->meta->make_immutable;
1;
