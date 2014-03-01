#!/usr/bin/perl -w
#
# This controller processes a SAML response and deals with
# user matching, creation and authentication
# Upon successful authentication it redirects to the URL 
# the user was trying to access.
# Upon failure it redirects to the Maestrano access
# unauthorized page
#
#
#-----------------------------------------------
# Define root folder
#-----------------------------------------------
use strict;
use CGI;
use CGI::Session;
use MIME::Base64 qw/ decode_base64 /;
use Cwd 'abs_path';

# Init CGI
my $cgi = CGI->new;
print "Content-type: text/html\n\n";

# Define root folder
$ENV{MAESTRANO_ROOT} = abs_path(__FILE__ . '/../../../');

# Load auth context
our $opts = {};
require $ENV{MAESTRANO_ROOT} . "/app/init/auth.pm";

# Get Session
my $sid = $cgi->cookie("CGISESSID") || undef;
my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
# session_start();
# if(isset($_SESSION['mno_previous_url'])) {
#   $previous_url = $_SESSION['mno_previous_url'];
# }
# session_unset();
# session_destroy();
# 
# # Restart session and inject previous url if defined
# session_start();
# if(isset($previous_url)) {
#   $_SESSION['mno_previous_url'] = $previous_url;
# }

# Get Maestrano Service
my $maestrano = MaestranoService->instance();

# Options variable
#my $opts = $opts || {};

# Process SAML response
my $saml_response = $cgi->param('SAMLResponse');
my $post = Net::SAML2::Binding::POST->new(cacert => $maestrano->get_settings->{sso_cacert_path});
my $ret = $post->handle_response($saml_response);


# Get the assertions
my $assertion;
if ($ret) {
  $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => decode_base64($saml_response));
  print Dumper($assertion->attributes);
}

try {
    if (defined($assertion)) {
        
        # Get Maestrano User
        my $sso_user = new MnoSsoUser($assertion, $session, $opts);
        
        # Try to match the user with a local one
        $sso_user->match_local();
        
        # If user was not matched then attempt
        # to create a new local user
        if (defined($sso_user->{local_id})) {
          $sso_user->create_local_user_or_deny_access();
        }
        
        # If user is matched then sign it in
        # Refuse access otherwise
        if ($sso_user->{local_id}) {
          $sso_user->sign_in();
          $cgi->redirect($maestrano->get_after_sso_sign_in_path())
        } else {
          $cgi->redirect($maestrano->get_sso_unauthorized_url())
        }
    }
    else {
        print 'There was an error during the authentication process.<br/>';
        print 'Please try again. If issue persists please contact support@maestrano.com';
    }
}
catch {
    print 'There was an error during the authentication process.<br/>';
    print 'Please try again. If issue persists please contact support@maestrano.com';
}