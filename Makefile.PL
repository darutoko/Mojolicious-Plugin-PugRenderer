use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PugRenderer',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PugRenderer.pm',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '7.35'},
  test         => {TESTS => 't/*.t'}
);
