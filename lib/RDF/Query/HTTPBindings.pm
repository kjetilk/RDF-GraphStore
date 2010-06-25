package RDF::Query::HTTPBindings::Role;

use Moose::Role;
use namespace::autoclean;

use RDF::Query;
use RDF::Trine::Model;
use RDF::Trine::Iterator;
use RDF::Trine::Serializer;

use Plack::Response;
use URI;
use URI::Escape;


=head1 NAME

RDF::Query::HTTPBindings::Role - A Moose::Role to implement SPARQL 1.1 HTTP Bindings

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



=head1 SYNOPSIS

This module attempts to track the SPARQL 1.1. HTTP Bindings document,
currently mostly as a discussion item.

It implements a Moose::Role with a default implementation, which
contains the specified queries.

=head1 DESCRIPTION

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
  my $res = Plack::Response->new;
  return $res;
}

=head2 post_response

What to do with a POST request. Returns a Plack::Response object.

=cut

sub post_response {
  my $self = shift;
  my $uri = _check_uri(shift);
  my $model = shift;
  my $res = Plack::Response->new;
  unless (defined($model) && $model->isa('RDF::Trine::Model')) {
    # Simply return if no payload. TODO: Ask WG about this
    $res->code(204);
    return $res;
  }
  # TODO: How do we escape the payload for security?
  my @triples;
  my $iterator = $model->get_statements(undef, undef, undef);
  while (my $statement = $iterator->next) {
    push (@triples, $statement);
  }

  my $bgp = RDF::Query::Algebra::BasicGraphPattern->new(@triples);

  my $sparql = "INSERT DATA { GRAPH <$uri> { " . $bgp->as_sparql  . "} }";
#  die $sparql;
  my $query = RDF::Query->new($sparql);
  # TODO: How do I know if it succeeded?
  
  # TODO: Support the "201 + Location" scenario
  return $res;
}

=head2 delete_response

What to do with a DELETE request. Returns a Plack::Response object.

=cut

sub delete_response {
  my $self = shift;
  my $res = Plack::Response->new;
  return $res;
}


sub _check_uri {
  my $uri = shift;
  confess 'No URI given' unless (defined($uri));
  $uri = uri_escape($uri, ">");
  return $uri if ($uri->isa('URI'));
  return URI->new($uri);
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



1;
