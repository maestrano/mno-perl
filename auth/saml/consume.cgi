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
use Try::Tiny;

# Define root folder
$ENV{MAESTRANO_ROOT} = abs_path(__FILE__ . '/../../../');

# Load auth context
our $opts = {};
require $ENV{MAESTRANO_ROOT} . "/app/init/auth.pm";

# Get CGI
my $cgi;
$cgi = $opts->{cgi} || CGI->new;

# Get Session and store session id
my $sid = $cgi->cookie("CGISESSID") || undef;
my $session;
$session = $opts->{session} || new CGI::Session(undef, $sid, {Directory=>'/tmp'});

# Keep session id as cookie (see redirect below where cookie is actually set)
my $cookie = $cgi->cookie(CGISESSID => $session->id);

# Get Maestrano Service
my $maestrano = MaestranoService->instance();

# Process SAML response
my $saml_response = $cgi->param('SAMLResponse');
my $post = Net::SAML2::Binding::POST->new(cacert => $maestrano->get_settings->{sso_cacert_path});
my $ret = $post->handle_response($saml_response);


# Get the assertions
my $assertion;
if ($ret) {
  $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => decode_base64($saml_response));
}

try {
    if (defined($assertion)) {
        
        # Get Maestrano User
        my $sso_user = new MnoSsoUser($assertion, $session, $opts);
        
        # Try to match the user with a local one
        $sso_user->match_local();
        
        # If user was not matched then attempt
        # to create a new local user
        if (!$sso_user->{local_id}) {
          $sso_user->create_local_user_or_deny_access();
        }
        
        # If user is matched then sign it in
        # Refuse access otherwise
        if ($sso_user->{local_id}) {
          $sso_user->sign_in();
          print $cgi->redirect(-uri =>$maestrano->get_after_sso_sign_in_path(), -cookie=>$cookie);
        } else {
          print $cgi->redirect($maestrano->get_sso_unauthorized_url());
        }
    }
    else {
        
        print 'There was an error during the authentication process.<br/>';
        print 'Please try again. If issue persists please contact support@maestrano.com';
    }
} catch {
    print "Content-type: text/html\n\n";
    print 'There was an error during the authentication process.<br/>';
    print 'Please try again. If issue persists please contact support@maestrano.com';
};