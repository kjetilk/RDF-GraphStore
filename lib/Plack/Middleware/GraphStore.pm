package Plack::Middleware::Foo;
use parent qw( Plack::Middleware );

sub call {
	my($self, $env) = @_;
	# Do something with $env

	# $self->app is the original app
	my $res = $self->app->($env);

	# Do something with $res
	return $res;
}
