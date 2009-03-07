use inc::Module::Install;
name 'XML-SAX-SimpleDispatcher';
all_from 'lib/XML/SAX/SimpleDispatcher.pm';

build_requires 'XML::SAX::Base';
build_requires 'XML::SAX::ParserFactory';
build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
