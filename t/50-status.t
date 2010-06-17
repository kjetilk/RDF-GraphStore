use Test::More;# tests => 7;

BEGIN {
  use_ok 'RDF::Query::HTTPBindings';
}

my $hb = RDF::Query::HTTPBindings->new();



done_testing;
