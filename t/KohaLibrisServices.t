# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl KohaLibrisServices.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;
BEGIN {
      use File::Basename;
      use lib dirname(__FILE__);
      use_ok('KohaLibrisServices')
};


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub hasApp {
  my $appName = shift;

  my $app = main->can($appName);

  return defined $app;
}

ok(hasApp('redirect_bibitem_app'), 'redirect_bibitem_app exists');
ok(hasApp('redirect_reserve_app'), 'redirect_reserve_app exists');
ok(hasApp('loan_status_app'),      'loan_status_app exists');

1;