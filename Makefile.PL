use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Int::Range::Parser',
    AUTHOR           => q{Nick Logan <ugexe@cpan.org>},
    VERSION_FROM     => 'lib/Data/Int/Range/Parser.pm',
    ABSTRACT_FROM    => 'lib/Data/Int/Range/Parser.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.5503, # For BUILD_REQUIRES
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.98_01,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    META_MERGE        => {
     
      "meta-spec" => { version => 2 },
     
      resources => {
     
        repository => {
            type => 'git',
            url => 'git://github.com/ugexe/Data-Int-Range-Parser.git',
            web => 'https://github.com/ugexe/Data-Int-Range-Parser',
        },
     
      },
     
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Int-Range-Parser-*' },
);
