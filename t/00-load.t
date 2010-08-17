#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'RDF::Query::HTTPBindings' ) || print "Bail out!
";
}

diag( "Testing RDF::Query::HTTPBindings $RDF::Query::HTTPBindings::VERSION, Perl $], $^X" );
