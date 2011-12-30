package Plack::App::RDF::GraphStore;
use parent qw( Plack::Component );
use RDF::GraphStore;
use Plack::Request;
use feature qw/switch/;

sub configure {
	my $self = shift;
	$self->{config} = shift;
	return $self;
}

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
	my $res;
	given ($req->method) {
		when ('GET') {
			$res = $self->{graphstore}->get_response->finalize;
		}
		when ('PUT') {
			$res = $self->{graphstore}->put_response->finalize;
		}
		when ('DELETE') {
			$res = $self->{graphstore}->delete_response->finalize;
		}
		when ('POST') {
			$res = $self->{graphstore}->post_response->finalize;
		}
		default {
			$res = [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ];
		}
	}
	return $res;
}

1;
