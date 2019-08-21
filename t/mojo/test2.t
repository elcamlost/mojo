package LiteApp;
use Mojolicious::Lite;

get '/' => sub {
    my $c   = shift;
    $c->render(json => {
        scalar => 'val_1',
        hash => {},
        array => [],
    });
};

package main;

use Test2::V0;
use Test::Mojo;

my $t = Test::Mojo->new('LiteApp');
$t->get_ok('/')->json_is(hash {
   field scalar => 'val_1';
   field hash => hash { end() };
   field array => array { end() };
   end();
});
