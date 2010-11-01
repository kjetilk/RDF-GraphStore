use inc::Module::Install;

name     'RDF-Query-HTTPBindings';
all_from 'lib/RDF/Query/HTTPBindings.pm';
readme_from 'lib/RDF/Query/HTTPBindings.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

test_requires 'Test::More';
test_requires 'Test::Moose';
test_requires 'Test::Exception';

requires 'Moose'			=> 0;
requires 'Log::Log4perl'		=> 0;
requires 'RDF::Trine'			=> 0.130;
requires 'RDF::Query'			=> 2.9;
requires 'Plack::Response'		=> 0;
requires 'namespace::autoclean'         => 0;
requires 'URI'                          => 0;

recommends 'Web::Simple'                => 0.004; # If you plan to run the server

author_tests('xt');

auto_set_repository;
auto_set_bugtracker;

write_doap_changes;

sign;

WriteAll;

