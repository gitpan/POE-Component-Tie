use Test::More tests => 59;
use strict;
use warnings;
use POE;
BEGIN { use_ok('POE::Component::Tie') };

my $scalar_session = POE::Session->create(
  inline_states => {
    _start    => sub {},
    _stop     => sub {},
    _default  => sub {ok(0)}, # Fail if we get any default events
    TIESCALAR => sub {ok(1)},
    FETCH     => sub {ok(1)},
    STORE     => sub {ok(1)},
    UNTIE     => sub {ok(1)},
  }
);

my $array_session = POE::Session->create(
  inline_states => {
    _start    => sub {},
    _stop     => sub {},
    _default  => sub {ok(0)}, # Fail if we get any default events
    TIEARRAY  => sub {ok(1)},
    FETCH     => sub {ok(1)},
    STORE     => sub {ok(1)},
    FETCHSIZE => sub {ok(1)},
    STORESIZE => sub {ok(1)},
    EXTEND    => sub {ok(1)},
    EXISTS    => sub {ok(1)},
    DELETE    => sub {ok(1)},
    CLEAR     => sub {ok(1)},
    PUSH      => sub {ok(1)},
    POP       => sub {ok(1)},
    SHIFT     => sub {ok(1)},
    UNSHIFT   => sub {ok(1)},
    SPLICE    => sub {ok(1)},
    UNTIE     => sub {ok(1)},
  }
);

my $hash_session = POE::Session->create(
  inline_states => {
    _start    => sub {},
    _stop     => sub {},
    _default  => sub {ok(0)}, # Fail if we get any default events
    TIEHASH   => sub {ok(1)},
    FETCH     => sub {ok(1)},
    STORE     => sub {ok(1)},
    DELETE    => sub {ok(1)},
    CLEAR     => sub {ok(1)},
    EXISTS    => sub {ok(1)},
    FIRSTKEY  => sub {ok(1)},
    NEXTKEY   => sub {ok(1)},
    SCALAR    => sub {ok(1)}, # 5.8.3 or higher only
    UNTIE     => sub {ok(1)},
  }
);

### Scalar tests
my $scalar;
ok(tie($scalar, 'POE::Component::Tie', $scalar_session, $poe_kernel), 'Actual tie of scalar');
ok($scalar = 'This is a test', 'STORE SCALAR');
ok($scalar eq 'This is a test', 'FETCH SCALAR');

ok(untie($scalar), 'UNTIE SCALAR');
### Array tests
my @array;
ok(tie(@array, 'POE::Component::Tie', $array_session, $poe_kernel), 'Actual tie of array');
ok(@array = qw/one two three/, 'STORE ARRAY');
ok($array[0] eq 'one', 'FETCH ARRAY');
ok(shift(@array), 'SHIFT ARRAY');
ok(pop(@array),   'POP ARRAY');
ok(scalar(@array), 'SCALAR ARRAY');
ok(push(@array, qw/four five six/), 'PUSH ARRAY');
ok(unshift(@array, qw/a b c/), 'UNSHIFT ARRAY');
ok(exists $array[1], 'EXISTS ARRAY');
# Need splice test TODO

ok(untie(@array), 'UNTIE ARRAY');
### Hash tests
my %hash;
ok(tie(%hash, 'POE::Component::Tie', $hash_session, $poe_kernel), 'Actual tie of hash');
ok($hash{'key'} = 'value', 'STORE HASH');
ok($hash{'key'} eq 'value', 'FETCH HASH');
foreach my $blah (keys %hash) {
  ok($hash{$blah} eq 'value', 'FETCH HASH');
}
ok(exists $hash{'key'}, 'HASH EXISTS');
ok(delete $hash{'key'}, 'HASH DELETE');

ok(untie(%hash), 'UNTIE HASH');
$poe_kernel->run();
