#-----------------------------------------------
# Define root folder and load base
#-----------------------------------------------
if (!defined($ENV{MAESTRANO_ROOT})) {
  $ENV{MAESTRANO_ROOT} = abs_path(__FILE__ . '/../../../');
}

require $ENV{MAESTRANO_ROOT} . '/app/init/base.pm';

#-----------------------------------------------
# Require your app specific files here
#-----------------------------------------------
my $app_path;
BEGIN {
  $ENV{APP_DIR} = abs_path($ENV{MAESTRANO_ROOT} . '/../');
  $app_path = $ENV{APP_DIR};
}
use lib $app_path;
use lib $app_path . '/lib';

use Bugzilla;
use Bugzilla::Constants;
use Bugzilla::Error;
use Bugzilla::Update;

#-----------------------------------------------
# Perform your custom preparation code
#-----------------------------------------------
# Set options to pass to the MnoSsoUser
#my $opts = {};
$opts->{connection} = Bugzilla->dbh;

1;