package POE::Component::Tie;

use strict;
use warnings;
use warnings::register;
use Carp;
use UNIVERSAL qw(isa);

our $VERSION = '0.01';

=head1 NAME

POE::Component::Tie - Perl extension that sends POE events on tie
method invocations.

=head1 SYNOPSIS

  use POE;
  use POE::Component::Tie;

  my $session = POE::Session->create(
    inline_states => {
      _start => sub {},
      STORE  => \&handler,
      [...] # place other handlers here you want for tie method events
   }
  );

  my $scalar;
  tie($scalar, "POE::Component::Tie", $session, $poe_kernel);
  $scalar = "Test!";

  $poe_kernel->run();

  sub handler {
    print "Got STORE event";
  }

=head1 DESCRIPTION

The B<POE::Component::Tie> package allows you to tie a scalar, array,
or hash, and then have the tie methods sent as events to a POE
session. Since there is no way to know the name of the variable being
tied, that information is not passed back to the POE event. You will
need to make a POE session and handlers for each variable you want to
tie with this package. It is also worth mentioning due to this, some
events that may be found in both ARRAY and HASH may pass something
different back. See the documentation to know what exactly to expect
back.

=head1 METHODS

List of each tie method that send events.

=head2 TIESCALAR

Sends the event B<TIESCALAR> with no arguments.

=cut

sub TIESCALAR {
  my $self    = shift;
  my $session = shift;
  my $kernel  = shift;
  my $data    = shift || "";
  unless((isa $session, "ARRAY") && (isa $session, "POE::Session")) {
    croak('->TIESCALAR: Not POE::Session Object');
  }
  unless((isa $kernel, "ARRAY") && (isa $kernel, "POE::Kernel")) {
    croak('->TIESCALAR: Not POE::Kernel Object');
  }
  my $internal = {
    SESSION => $session,
    KERNEL  => $kernel,
    DATA    => $data,
    TYPE    => "SCALAR",
  };
  $kernel->post($session, 'TIESCALAR');
  return bless $internal, $self;
}

=pod

=head2 TIEARRAY

Sends the event B<TIEARRAY> with no arguments.

=cut

sub TIEARRAY {
  my $self = shift;
  my $session = shift;
  my $kernel  = shift;
  my @data = @_ || [];
  unless((isa $session, "ARRAY") && (isa $session, "POE::Session")) {
    croak('->TIESCALAR: Not POE::Session Object');
  }
  unless((isa $kernel, "ARRAY") && (isa $kernel, "POE::Kernel")) {
    croak('->TIESCALAR: Not POE::Kernel Object');
  }
  my $internal = {
    SESSION => $session,
    KERNEL  => $kernel,
    DATA    => @data,
    TYPE    => "ARRAY",
  };
  $kernel->post($session, 'TIEARRAY');
  return bless $internal, $self;
}

=pod

=head2 TIEHASH

Sends the event B<TIEHASH> with no arguments.

=cut

sub TIEHASH {
  my $self = shift;
  my $session = shift;
  my $kernel  = shift;
  my $data_ref = shift || {};
  unless((isa $session, "ARRAY") && (isa $session, "POE::Session")) {
    croak('->TIESCALAR: Not POE::Session Object');
  }
  unless((isa $kernel, "ARRAY") && (isa $kernel, "POE::Kernel")) {
    croak('->TIESCALAR: Not POE::Kernel Object');
  }
  my $internal = {
    SESSION => $session,
    KERNEL  => $kernel,
    DATA    => $data_ref,
    TYPE    => "HASH",
  };
  $kernel->post($session, 'TIEHASH');
  return bless $internal, $self;
}

=pod

=head2 CLEAR

Sends the event B<CLEAR>, and also sends what was contained in the
variable as C<ARG0> in a reference.

=over 4

=item EXAMPLES

  sub handler {
    my $clear_ref = $_[ARG0]
    my %hash  = %{$clear_ref}; # if was a hash
    my @array = @{$clear_ref}; # if was an array
    ...
  }

=back

=cut

sub CLEAR {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  $self->{KERNEL}->post($self->{SESSION}, 'CLEAR', $self->{DATA});
  if ($self->{TYPE} eq "ARRAY") {
    $self->{KERNEL}->post($self->{SESSION}, 'CLEAR', $self->{DATA});
    return $self->{DATA} = [];
  }
  elsif ($self->{TYPE} eq "HASH") {
    $self->{KERNEL}->post($self->{SESSION}, 'CLEAR', %{$self->{DATA}});
    return %{$self->{DATA}} = ();
  }
}

=pod

=head2 DELETE

Sends the event B<DELETE>, and depending on the type of variable being
tied, some arguments.

=over 3

=item HASH

From the POE event, C<ARG0> will contain a hash reference with the
keys C<key>, and C<value>. The key C<key> will be the hash key, and
C<value> will be the value being deleted.

=item ARRAY

For an array, it will be the same as a hash, but instead of the hash
key C<key>, it will be C<index>.

=back

=over 4

=item EXAMPLE

  sub handler {
    my $deleted = $_[ARG0];
    print "The index: $deleted->{index} was deleted, the value was $deleted->{value}\n"; # array
    print "The key: $deleted->{key} was deleted, the value was $deleted->{value}\n";     # hash
    ...
  }

=back

=cut

sub DELETE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  if ($self->{TYPE} eq "ARRAY") {
    my $index = shift;
    $self->{KERNEL}->post($self->{SESSION}, 'DELETE', {index => $index, value => $self->{DATA}->[$index]});
    return $self->STORE($index, undef);
  }
  elsif ($self->{TYPE} eq "HASH") {
    my $key = shift;
    $self->{KERNEL}->post($self->{SESSION}, 'DELETE', {key => $key, value => $self->{DATA}->{$key}});
    return delete $self->{DATA}->{$key};
  }
}

=pod

=head2 DESTROY

Not implemented.

=cut

sub DESTROY {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  #(in cleanup) Can't call method "post" on an undefined value
  #$self->{KERNEL}->post($self->{SESSION}, 'DESTROY');
}

=pod

=head2 EXISTS

Sends the event B<EXISTS>, and depending on the type of variable being
tied, some arguments.

=over 3

=item HASH

From the POE event, C<ARG0> will contain a hash reference with the
keys C<key>, and C<exists>. The key C<key> is the key of the hash,
while C<exists> is the return value of C<exists> on that key.

=item ARRAY

For an array, it will be the same as a hash, but instead of the hash
key C<key>, it will be C<index>.

=back

=over 4

=item EXAMPLE

  sub handler {
    my $exists = $_[ARG0];
    print "$exists->{key} return value from exists is $exists->{exists}\n";   # hash
    print "$exists->{index} return value from exists is $exists->{exists}\n"; # array
    ...
  }

=back

=cut

sub EXISTS {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  if ($self->{TYPE} eq "ARRAY") {
    my $index = shift;
    if (!defined $self->{DATA}->[$index]) {
      $self->{KERNEL}->post($self->{SESSION}, 'EXISTS', {index => $index, exists => 0});
      return 0;
    }
    else {
      $self->{KERNEL}->post($self->{SESSION}, 'EXISTS', {index => $index, exists => 1});
      return 1;
    }
  }
  elsif ($self->{TYPE} eq "HASH") {
    my $key = shift;
    my $exists = exists $self->{DATA}->{$key};
    $self->{KERNEL}->post($self->{SESSION}, 'EXISTS', {key => $key, exists => $exists});
    return $exists;
  }
}

=pod

=head2 EXTEND

Sends the event B<EXTEND>, and will send as C<ARG0>, the size
extended.

=over 4

=item EXAMPLE

  sub handler {
    my $size = $_[ARG0];
    ...
  }

=back

=cut

sub EXTEND {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $count = shift;
  $self->{KERNEL}->post($self->{SESSION}, 'EXTEND', $count);
  $self->STORESIZE($count);
}

=pod

=head2 FETCH

Sends the event B<FETCH>, and depending on the type of variable being
tied, some arguments.

=over 3

=item SCALAR

From the POE event, C<ARG0> will contain what is being fetched.

=item HASH

From the POE event, C<ARG0> will contain a hash reference with the
keys C<key> and C<value>, which will contain the hash key and the
value of that key.

=item ARRAY

From the POE event, C<ARG0> will contain a hash reference with the
keys C<index> and C<value>, which will contain the index position and
value of that position.

=back

=over 4

=item EXAMPLES

  # Scalar
  sub handler {
    my $fetched = $_[ARG0];
    print "got $fetched\n";
  }

  # Array or Hash
  sub handler {
    my $fetched = $_[ARG0];
    print "Fetched: $fetched->{value}\n";
    ...
  }

=back

=cut

sub FETCH {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  if ($self->{TYPE} eq "SCALAR") {
    $self->{KERNEL}->post($self->{SESSION}, 'FETCH', $self->{DATA});
    return $self->{DATA};
  }
  elsif ($self->{TYPE} eq "ARRAY") {
    my $index = shift;
     $self->{KERNEL}->post($self->{SESSION}, 'FETCH', {index => $index, value => $self->{DATA}->[$index]});
    return $self->{DATA}->[$index];
  }
  elsif ($self->{TYPE} eq "HASH") {
    my $key = shift;
    $self->{KERNEL}->post($self->{SESSION}, 'FETCH', {key => $key, value => $self->{DATA}->{$key}});
    return $self->{DATA}->{$key};
  }
}

=pod

=head2 FETCHSIZE

Sends the event B<FETCHSIZE>, and will send as C<ARG0>, the size of
the array.

=over 4

=item EXAMPLE

  sub handler {
    my $size = $_[ARG0];
    ...
  }

=back

=cut

sub FETCHSIZE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $size = scalar(@{$self->{DATA}});
  $self->{KERNEL}->post($self->{SESSION}, 'FETCHSIZE', $size);
  return $size;
}

=pod

=head2 FIRSTKEY

Sends the event B<FIRSTKEY>, and will send as C<ARG0>, the first key.

=over 4

=item EXAMPLE

  sub handler {
    my $key = $_[ARG0];
    ...
  }

=back

=cut

sub FIRSTKEY {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $a = keys %{$self->{DATA}}; # reset the each operator.
  my $each = each %{$self->{DATA}};
  $self->{KERNEL}->post($self->{SESSION}, 'FIRSTKEY', $each);
  return $each;
}

=pod

=head2 NEXTKEY

Sends the event B<NEXTKEY>, and will send as C<ARG0>, the next key.

=over 4

=item EXAMPLE

  sub handler {
    my $key = $_[ARG0];
    ...
  }

=back

=cut

sub NEXTKEY {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $each = each %{$self->{DATA}};
  $self->{KERNEL}->post($self->{SESSION}, 'NEXTKEY', $each);
  return $each;
}

=pod

=head2 POP

Sends the event B<POP>, and will send as C<ARG0>, what was returned from pop.

=over 4

=item EXAMPLE

  sub handler {
    my $popped = $_[ARG0];
    ...
  }

=back

=cut

sub POP {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $pop = pop @{$self->{DATA}};
  $self->{KERNEL}->post($self->{SESSION}, 'POP', $pop);
  return $pop;
}

=pod

=head2 PUSH

Sends the event B<PUSH>, C<ARG0> will contain a hash reference with
the keys C<list>, and C<size>. The key C<list> will be an array of
what was pushed on, and C<return> will be the value returned from
C<push>.

=over 4

=item EXAMPLE

  sub handler {
    my $pushed = $_[ARG0];
    print "Caught PUSH: List pushed: '@{$pushed->{list}}', return value: $pushed->{return}\n";
    ...
  }

=back

=cut

sub PUSH {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my @list = @_;
  push(@{$self->{DATA}}, @list);
  my $return = $self->FETCHSIZE();
  $self->{KERNEL}->post($self->{SESSION}, 'PUSH', {list => \@list, return => $return});
  return $return;
}

=pod

=head2 SCALAR

Not implimented yet. New in Perl 5.8.3

=cut

# TODO

=pod

=head2 SHIFT

Sends the event B<SHIFT>, and will send as C<ARG0>, what was returned
from shift.

=over 4

=item EXAMPLE

  sub handler {
    my $shifted = $_[ARG0];
    ...
  }

=back

=cut

sub SHIFT {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $shift = shift @{$self->{DATA}};
  $self->{KERNEL}->post($self->{SESSION}, 'SHIFT', $shift);
  return $shift;
}

=pod

=head2 SPLICE

Sends the event B<SPLICE>, nothing returned, yet. TODO

=over 4

=item EXAMPLE

  sub handler {
    print "Got splice\n";
    ...
  }

=back

=cut

# TODO need to figure how to send this POE event
sub SPLICE {
  my $self    = shift;
  confess "I am not a class method" unless ref $self;
  $self->{KERNEL}->post($self->{SESSION}, 'SPLICE');
  my $size   = $self->FETCHSIZE;
  my $offset = @_ ? shift : 0;
  $offset += $size if $offset < 0;
  my $length = @_ ? shift : $size-$offset;
  return splice(@{$self->{DATA}},$offset,$length,@_);
}

=pod

=head2 STORE

Sends the event B<STORE>, and depending on the type of variable being
tied, some arguments.

=over 3

=item SCALAR

From the POE event, C<ARG0> will what the value of the scalar used to
be, while C<ARG1> will be the new value.

=item HASH

From the POE event, C<ARG0> will contain will contain a hash reference
with the keys C<key>, and C<value>, which will contain the value of
what the value used to be. While C<ARG1> will contain a hash reference
with the same structure, except its key C<value> will contain the new
value of the hash.

=item ARRAY

For an array, it will be the same as a hash, but instead of the hash
key C<key>, it will be C<index>.

=back

=over 4

=item EXAMPLES

  # Scalar
  sub handler {
    my ($orig, $new) = @_[ARG0, ARG1];
    ...
  }

  # Array or Hash
  sub handler {
    my ($orig, $new) = @_[ARG0, ARG1];
    print "$orig->{value} now $new->{value}\n";
    ...
  }

=back

=cut

sub STORE {
  my $self  = shift;
  confess "I am not a class method" unless ref $self;
  if ($self->{TYPE} eq "SCALAR") {
   my $value = shift;
    $self->{KERNEL}->post($self->{SESSION}, 'STORE', $self->{DATA}, $value);
    return $self->{DATA} = $value;
  }
  elsif ($self->{TYPE} eq "ARRAY") {
    my $index = shift;
    my $value = shift;
    $self->{KERNEL}->post($self->{SESSION}, 'STORE',
      {index => $index, value => $self->{DATA}->[$index]},
      {index => $index, value => $value}
    );
    return $self->{DATA}->[$index] = $value;
  }
  elsif ($self->{TYPE} eq "HASH") {
    my $key   = shift;
    my $value = shift;
    $self->{KERNEL}->post($self->{SESSION}, 'STORE',
      {key => $key, value => $self->{DATA}->{$key}},
      {key => $key, value => $value}
    );
    return $self->{DATA}->{$key} = $value;
  }
}

=pod

=head2 STORESIZE

Sends the event B<FIRSTKEY> the size stored as C<ARG0>.

=over 4

=item EXAMPLE

  sub handler {
    my $size = $_[ARG0];
    print "Got STORESIZE of $size\n";
    ...
  }

=back

=cut

sub STORESIZE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $count = shift;
  $self->{KERNEL}->post($self->{SESSION}, 'STORESIZE', $count);
  if ($count > $self->FETCHSIZE()) {
    foreach ($count - $self->FETCHSIZE() .. $count - 1) {
      $self->STORE($_, undef);
    }
  }
  elsif ($count < $self->FETCHSIZE()) {
    foreach (0 .. $self->FETCHSIZE() - $count - 2) {
      $self->POP();
    }
  }
}

=pod

=head2 UNSHIFT

Sends the event B<UNSHIFT>, C<ARG0> will contain a hash reference with
the keys C<list>, and C<size>. The key C<list> will be an array of
what was unshifted on, and C<return> will be the value returned from
C<unshift>.

=over 4

=item EXAMPLE

  sub handler {
    my $unshifted = $_[ARG0];
    print "Caught UNSHIFT: List unshifted: '@{$unshifted->{list}}', return value: $unshifted->{return}\n";
    ...
  }

=back

=cut

sub UNSHIFT {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my @list = @_;
  unshift(@{$self->{DATA}}, @list);
  my $size = $self->FETCHSIZE();
  $self->{KERNEL}->post($self->{SESSION}, 'UNSHIFT', {list => \@list, return => $size});
  return $size;
}

=pod

=head2 UNTIE

Sends the event B<UNTIE> with no arguments.

=over 4

=item EXAMPLE

  sub handler {
    print "Got UNTIE\n";
  }

=back

=cut

sub UNTIE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  $self->{KERNEL}->post($self->{SESSION}, 'UNTIE');
  return $self->{DATA}    if ($self->{TYPE} eq "SCALAR");
  return @{$self->{DATA}} if ($self->{TYPE} eq "ARRAY");
  return %{$self->{DATA}} if ($self->{TYPE} eq "HASH");
}

=pod

=head1 EXPORT

None by default.

=head1 BUGS

C<SPLICE> does not pass any arguments to the B<SPLICE> event, like it should.

If C<DESTROY> method sends event to POE, the following warning is issued: 'C<(in
cleanup) Can't call method "post" on an undefined value...>'. It would be nice
to be able to send an event on C<DESTROY>.

=head1 TODO

=over 2

=item Add C<TIEHANDLE> and it's methods.

=item Add C<SCALAR> for hashes (5.8.3 and higher).

=item SPLICE needs to pass arguments.

=item More tests

=item Documentation, Documentation, Documentation!

=back

=head1 VERSION

This is an alpha version release. Please use at your own risk. Bug reports,
patches, or comments, please send an email to the address below.

=head1 SEE ALSO

L<POE>, L<perltie>

=head1 AUTHOR

Larry Shatzer, Jr., E<lt>larrysh@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Larry Shatzer, Jr.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

