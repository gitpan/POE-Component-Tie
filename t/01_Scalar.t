use Test::More tests => 5;
use strict;
use warnings;
use POE;
use POE::Component::Tie;

my $session = POE::Session->create(
  inline_states => {
    _start    => sub {},
    TIESCALAR => sub {ok(1)},
    FETCH     => sub {
      my $fetch = $_[ARG0];
      ok($fetch eq "something", "FETCH SCALAR EVENT");
    },
    STORE     => sub {
      my ($prev, $new) = @_[ARG0, ARG1];
      ok($prev eq "", "STORE PREV EVENT");
      ok($new  eq "something" , "STORE NEW EVENT");
    },
    UNTIE     => sub {ok(1)},
  }
);

my $scalar;
tie($scalar, 'POE::Component::Tie', $session, $poe_kernel);
$scalar = "something";
ok($scalar eq "something", "FETCH SCALAR");

$poe_kernel->run();
