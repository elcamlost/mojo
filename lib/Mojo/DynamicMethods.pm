package Mojo::DynamicMethods;
use Mojo::Base -strict;

use Hash::Util::FieldHash 'fieldhash';
use Mojo::Util qw(class_to_path monkey_patch);

sub import {
  my ($flag, $caller) = ($_[1] // '', caller);
  return unless $flag eq '-dispatch';

  my $dyn_pkg = "${caller}::_Dynamic";
  monkey_patch $dyn_pkg, 'can', sub {
    my ($self, $method, @rest) = @_;

    # Delegate to our parent's "can" if there is one, without breaking if not
    my $can = $self->${\($self->next::can || 'UNIVERSAL::can')}($method, @rest);
    return undef unless $can;
    no warnings 'once';
    my $h = do { no strict 'refs'; *{"${dyn_pkg}::${method}"}{CODE} };
    return $h && $h eq $can ? undef : $can;
  };

  $INC{class_to_path($dyn_pkg)} = __FILE__;
  {
    no strict 'refs';
    unshift @{"${caller}::ISA"}, $dyn_pkg;
  }
}

sub register {
  my ($target, $object, $name, $code) = @_;

  state %dyn_methods;
  state $setup = do { fieldhash %dyn_methods; 1 };

  my $dyn_pkg = "${target}::_Dynamic";
  monkey_patch($dyn_pkg, $name, $target->BUILD_DYNAMIC($name, \%dyn_methods))
    unless do { no strict 'refs'; *{"${dyn_pkg}::${name}"}{CODE} };
  $dyn_methods{$object}{$name} = $code;
}

1;

=encoding utf8

=head1 NAME

Mojo::DynamicMethods - Fast dynamic method dispatch

=head1 SYNOPSIS

  package MyClass;
  use Mojo::Base -base;

  use Mojo::DynamicMethods -dispatch;

  sub BUILD_DYNAMIC {
    my ($class, $method, $dyn_methods) = @_;
    return sub {
      my $self    = shift;
      my $dynamic = $dyn_methods->{$self}{$method};
      return $self->$dynamic(@_) if $dynamic;
      my $package = ref $self;
      Carp::croak
        qq{Can't locate object method "$method" via package "$package"};
    };
  }

  sub add_helper {
    my ($self, $name, $cb) = @_;
    Mojo::DynamicMethods::register 'MyClass', $self, $name, $cb;
  }

  package main;

  # Generate methods dynamically (and hide them from "can")
  my $obj = MyClass->new;
  $obj->add_helper(foo => sub { warn 'Hello Helper!' });
  $obj->foo;
  warn 'Method hidden from $obj->can(...)' unless $obj->can('foo');

=head1 DESCRIPTION

L<Mojo::DynamicMethods> provides dynamic method dispatch for per-object helper
methods without requiring use of C<AUTOLOAD>.

To opt your class into dynamic dispatch, simply pass the C<-dispatch> flag.

  use Mojo::DynamicMethods -dispatch;

And implement a C<BUILD_DYNAMIC> method in your class, making sure that the key
you use to lookup methods in C<$dyn_methods> is the same thing you pass as
C<$ref> to L</"register">.

=head1 FUNCTIONS

L<Mojo::DynamicMethods> implements the following functions.

=head2 register

  Mojo::DynamicMethods::register $class, $ref, $name, $cb;

Registers the method C<$name> as eligible for dynamic dispatch for C<$class>,
and sets C<$cb> to be looked up for C<$name> by reference C<$ref> in a dynamic
method contructed by C<BUILD_DYNAMIC>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
