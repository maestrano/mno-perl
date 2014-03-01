#-----------------------------------------------
# Define root folder and load base
#-----------------------------------------------
if (!defined($ENV{MAESTRANO_ROOT})) {
  $ENV{MAESTRANO_ROOT} = abs_path(__FILE__ . '/../../../');
}

#-----------------------------------------------
# Load Libraries & Settings
#-----------------------------------------------
require $ENV{MAESTRANO_ROOT} . '/app/init/_lib_loader.pm';
require $ENV{MAESTRANO_ROOT} . '/app/init/_config_loader.pm';

1;