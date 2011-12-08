#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'RDF::GraphStore' ) || print "Bail out!";
}

diag( "Testing RDF::GraphStore $RDF::GraphStore::VERSION, Perl $], $^X" );
