use inc::Module::Install;

name     'RDF-Query-HTTPBindings';
all_from 'lib/RDF/Query/HTTPBindings.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

