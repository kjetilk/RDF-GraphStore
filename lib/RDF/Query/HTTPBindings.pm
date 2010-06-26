package RDF::Query::HTTPBindings;

use Moose;
use namespace::autoclean;

use RDF::Query 2.9;
use RDF::Trine::Model;
use RDF::Trine::Iterator;
use RDF::Trine::Serializer;
use RDF::Trine::Serializer::NTriples;

use Plack::Response;
use URI;
use URI::Escape;


=head1 NAME

RDF::Query::HTTPBindings::Role - A Moose::Role to implement SPARQL 1.1 HTTP Bindings

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

=head2 get_response($uri | $uri_string)

What to do with a GET request. Takes a URI object or a simple string
as argument. Returns a Plack::Response object.

=cut

sub get_response {
  my $self = shift;
  my $uri = _check_uri(shift);
  my $res = Plack::Response->new;
  my $sparql = "CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <$uri> { ?s ?p ?o } }";
  my $query = RDF::Query->new($sparql);
  my $iterator = $query->execute($self->model);
  # Need to serialize first to find the number of returned triples
  my ($ct, $serializer) = RDF::Trine::Serializer->negotiate('request_headers' => $self->headers_in);
  my $output = $serializer->serialize_iterator_to_string($iterator);
  # TODO: Ask the WG if this is an appropriate way to figure out if a
  # request should return 404
  if (defined($iterator) && ($iterator->is_graph) && ($iterator->count > 0)) {
    $res->body($output);
    $res->content_type($ct);
    $res->content_length(bytes::length($output));
    $res->status(200);
  } else {
    $res->status(404);
    $res->content_type('text/plain');
    $res->body('Graph not found');
  }

  return $res;
}

=head2 put_response

What to do with a PUT request. Returns a Plack::Response object.

=cut

sub put_response {
  my $self = shift;
  my $uri = _check_uri(shift);
  my $new_model = shift;
  my $res = Plack::Response->new;
  my $sparql = "DROP GRAPH <$uri>;\nCREATE GRAPH <$uri>;\n";
  if (defined($new_model) && $new_model->isa('RDF::Trine::Model')) {
    # TODO: How do we escape the payload for security?
    $sparql = "DROP GRAPH <$uri>;\nCREATE GRAPH <$uri>;\nINSERT DATA { GRAPH <$uri> {\n\t" . _serialize_payload( $new_model ) . '} }';
    $res->location($uri);
  }
  warn $sparql;
  my $query = RDF::Query->new($sparql, { update => 1 }) || confess RDF::Query->error;
  $query->execute($self->model); # TODO: What could go wrong here and how do we deal with it?
  $res->code(201);
  return $res;
}


=head2 post_response

What to do with a POST request. Returns a Plack::Response object.

=cut

sub post_response {
  my $self = shift;
  my $uri = _check_uri(shift);
  my $add_model = shift;
  my $res = Plack::Response->new;
  unless (defined($add_model) && $add_model->isa('RDF::Trine::Model')) {
    # Simply return if no payload. TODO: Ask WG about this
    $res->code(204);
    return $res;
  }
  # TODO: How do we escape the payload for security?
  my $sparql = "INSERT DATA { GRAPH <$uri> {\n\t" . _serialize_payload($add_model) . '} }';
  my $query = RDF::Query->new($sparql, { update => 1 }) || confess RDF::Query->error;
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
  my $uri = _check_uri(shift);
  my $res = Plack::Response->new;
  my $sparql = "DROP GRAPH <$uri>";
  my $query = RDF::Query->new($sparql, { update => 1 }) || confess RDF::Query->error;
  $query->execute($self->model); # TODO: What could go wrong here and how do we deal with it?
  $res->code(204);
  return $res;
}



sub _check_uri {
  my $uri = shift;
  confess 'No URI given' unless (defined($uri));
  # TODO: Is this sufficient input sanatizing?
  $uri = uri_escape($uri, ">");
  return $uri if ($uri->isa('URI'));
  return URI->new($uri);
}

sub _serialize_payload {
  my $modify_model = shift;
  confess 'No model given' unless (defined($modify_model) && $modify_model->isa('RDF::Trine::Model'));
  my $serializer = RDF::Trine::Serializer::NTriples->new();
  return $serializer->serialize_model_to_string ( $modify_model );
}


=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-query-httpbindings at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Query-HTTPBindings>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




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
