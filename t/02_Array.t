use Test::More tests => 1;
use strict;
use POE;
use POE::Component::Tie;
use Data::Dumper;

my $session = POE::Session->create(
  inline_states => {
    _start => sub {
      my $heap = $_[HEAP];
      @{$heap->{testresults}} = ();
      @{$heap->{test}} = (
          'TIEARRAY',
          'CLEAR => $VAR1 = [];
',
          'CLEAR => $VAR1 = [];
',
          'EXTEND 3',
          'STORESIZE: 3',
          'FETCHSIZE: 0',
          'FETCHSIZE: 0',
          'DELETE ARRAY[1] was deleted, the value was two',
          'SHIFT: one',
          'POP: three',
          'FETCHSIZE: 5',
          'PUSH: pushed onto the list, return: 5',
          'FETCHSIZE: 5',
          'FETCHSIZE: 9',
          'UNSHIFTED: unshifted onto the list, return: 9',
          'FETCHSIZE: 9',
          'EXISTS: 1 returns 1'
        );
    },
    _stop  => sub {
      my $heap = $_[HEAP];
      is_deeply($heap->{testresults}, $heap->{test});
      
    },
    _default => sub {
      print "Default caught an unhandled $_[ARG0] event.\n";
      print "The $_[ARG0] event was given these parameters: @{$_[ARG1]}\n";
    },
    TIEARRAY  => sub {
      my $heap = $_[HEAP];
      push(@{$heap->{testresults}}, "TIEARRAY");
    },
    FETCH     => sub {
      my ($fetched, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "FETCH: ARRAY[$fetched->{index}] = $fetched->{value}");
    },
    STORE     => sub {
      my ($orig, $new, $heap) = @_[ARG0, ARG1];
      push(@{$heap->{testresults}}, "STORE: ARRAY[$orig->{index}] was '$orig->{value}', now '$new->{value}'");
    },
    FETCHSIZE => sub {
      my ($size, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "FETCHSIZE: $size");
    },
    STORESIZE => sub {
      my ($size, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "STORESIZE: $size");
    },
    EXTEND    => sub {
      my ($size, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "EXTEND $size");
    },
    EXISTS    => sub {
      my ($exists, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "EXISTS: $exists->{index} returns $exists->{exists}");
    },
    DELETE    => sub {
      my ($deleted, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "DELETE ARRAY[$deleted->{index}] was deleted, the value was $deleted->{value}");
    },
    CLEAR     => sub {
      my ($return, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "CLEAR => " . Dumper($return));
    },
    PUSH      => sub {
      my ($pushed, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "PUSH: @{$pushed->{list}}, return: $pushed->{return}");
    },
    POP       => sub {
      my ($popped, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "POP: $popped");
    },
    SHIFT     => sub {
      my ($shifted, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "SHIFT: $shifted");
    },
    UNSHIFT   => sub {
      my ($unshifted, $heap) = @_[ARG0, HEAP];
      push(@{$heap->{testresults}}, "UNSHIFTED: @{$unshifted->{list}}, return: $unshifted->{return}");
    },
    SPLICE    => sub {
      print "Caught SPLICE"; # TODO
    },
    UNTIE     => sub {
      print "Caught UNTIE"; # Taken care of elsewhere
    },
  },
);

my @array;

tie(@array, "POE::Component::Tie", $session, $poe_kernel);
@array = qw/one two three/;
delete $array[1];
my $s = shift @array;
my $p = pop @array;
push(@array, qw/pushed onto the list/);
unshift(@array, qw/unshifted onto the list/);
exists($array[1]);

$poe_kernel->run();
