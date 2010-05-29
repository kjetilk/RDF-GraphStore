use inc::Module::Install;

name     'RDF-Query-HTTPBindings';
all_from 'lib/RDF/Query/HTTPBindings/Role.pm';
readme_from 'lib/RDF/Query/HTTPBindings/Role.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

test_requires 'Test::More';


requires 'Moose'			=> 0;
requires 'Log::Log4perl'		=> 0;
requires 'RDF::Trine'			=> 0.122;
requires 'RDF::Query'			=> 2.0;
requires 'HTTP::Response'		=> 0;

auto_set_repository;
auto_set_bugtracker;

write_doap_changes;

sign;

WriteAll;

