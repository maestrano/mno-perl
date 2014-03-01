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
$ENV{APP_DIR} = abs_path($ENV{MAESTRANO_ROOT} . '/../../');


#-----------------------------------------------
# Perform your custom preparation code
#-----------------------------------------------
# Set options to pass to the MnoSsoUser
my $opts = {};
# $opts{'connection'} = new DB::Connection(some_db_params_set_above)

1;