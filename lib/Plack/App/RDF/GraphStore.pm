package Plack::App::RDF::GraphStore;
use parent qw( Plack::Component );
use RDF::GraphStore;
use Plack::Request;

sub prepare_app {
	my $self = shift;
	my $store = RDF::Trine::Store->new($self->{config});
	my $model = RDF::Trine::Model->new($store);
	$self->{graphstore} = RDF::GraphStore->new(model => $model);
}

sub call {
	my($self, $env) = @_;
	my $req = Plack::Request->new($env);
	$self->{graphstore}->init($req->headers, $req->uri);
	my $res = $self->{graphstore}->get_response->finalize;

	return $res;
}

1;
