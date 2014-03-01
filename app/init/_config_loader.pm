# Initialize mno_settings variable
our $mno_settings = new MnoSettings();

# Require Config files
require $ENV{MAESTRANO_ROOT} . '/app/config/1_app.pm';
require $ENV{MAESTRANO_ROOT} . '/app/config/2_maestrano.pm';

# Configure Maestrano Service
MaestranoService->configure($mno_settings);


1;