use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Mojolicious::Lite;
my $t = Test::Mojo->new;

plugin Config =>
  {default => {deep => {nested => {array => []}}}, deep_merge => 1};

is ref $t->app->config->{deep}{nested}{hash}, 'HASH', 'hash is ok and exists';
is ref $t->app->config->{deep}{nested}{array}, 'ARRAY',
  'array is ok and exists';

done_testing;