use Test::More tests => 9;
use strict;
use warnings;
use POE;
use POE::Component::Tie;

my $hash_session = POE::Session->create(
  inline_states => {
    _start    => sub {},
    TIEHASH   => sub {ok(1)},
    FETCH     => sub {
      my $fetch = $_[ARG0];
      ok($fetch->{key} eq "key", "FETCH");
      ok($fetch->{value} eq "value", "FETCH");
    },
    STORE     => sub {
      my ($prev, $new) = @_[ARG0, ARG1];
      ok($prev->{key} eq "key", "STORE");
      ok(!$prev->{value}, "STORE");
      ok($new->{key} eq "key", "STORE");
      ok($new->{value} eq "value", "STORE");
    },
    DELETE    => sub {},
    CLEAR     => sub {},
    EXISTS    => sub {},
    FIRSTKEY  => sub {},
    NEXTKEY   => sub {},
    SCALAR    => sub {}, # 5.8.3 or higher only
    UNTIE     => sub {},
  }
);

### Hash tests
my %hash;
ok(tie(%hash, 'POE::Component::Tie', $hash_session, $poe_kernel), 'Actual tie of hash');
$hash{key} = "value";
ok($hash{key} eq "value", "FETCH");

$poe_kernel->run();