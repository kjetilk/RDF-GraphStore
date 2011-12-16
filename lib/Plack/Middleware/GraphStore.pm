package Plack::Middleware::GraphStore;
use parent qw( Plack::Middleware );
use RDF::GraphStore;

sub prepare_app {
	my $self = shift;
	my $store = RDF::Trine::Store->new($self->{config});
	my $model = RDF::Trine::Model->new($store);
	$self->{graphstore} = RDF::GraphStore->new(model => $model);
}

sub call {
	my($self, $env) = @_;
	my $req = Plack::Request->new($env);
	$gs->init($req->headers, $req->uri);
	my $res = $self->app->($env);


	# Do something with $res
	return $res;
}

1;
