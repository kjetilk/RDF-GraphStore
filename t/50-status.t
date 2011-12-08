use Test::More;# tests => 7;

BEGIN {
  use_ok 'RDF::GraphStore';
}

my $hb = RDF::GraphStore->new();



done_testing;
