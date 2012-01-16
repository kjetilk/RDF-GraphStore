use inc::Module::Install;

name     'RDF-GraphStore';
all_from 'lib/RDF/GraphStore.pm';
readme_from 'lib/RDF/GraphStore.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

perl_version '5.010';
test_requires 'Test::More';
test_requires 'Test::Moose';
test_requires 'Test::Exception';
test_requires 'HTTP::Request::Common';

requires 'Moose'			=> 0;
requires 'Log::Log4perl'		=> 0;
requires 'RDF::Trine'			=> 0.130;
requires 'RDF::Query'			=> 2.9;
requires 'Plack::Response'		=> 0;
requires 'namespace::autoclean'         => 0.12;
requires 'URI'                          => 0;

requires 'Config::JFDI'                 => 0;

author_tests('xt');

auto_set_repository;
auto_set_bugtracker;

write_doap_changes;

sign;

WriteAll;

