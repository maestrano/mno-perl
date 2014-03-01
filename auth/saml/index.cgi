#!/usr/bin/perl -w
#
# This controller creates a SAML request and redirects to
# Maestrano SAML Identity Provider
#
#
use strict;
use CGI;
use Cwd 'abs_path';

# Init CGI
my $q = CGI->new;

# Define root folder
$ENV{MAESTRANO_ROOT} = abs_path(__FILE__ . '/../../../');

# Load auth context
require $ENV{MAESTRANO_ROOT} . "/app/init/auth.pm";
 
# Get the Maestrano Service
my $maestrano = MaestranoService->instance();

# Build SAML IDP
my $idp = Net::SAML2::IdP->new($maestrano->get_settings->get_saml_idp_settings);

#print $maestrano->get_settings->get_saml_request_settings->{destination};

# Build Request
my $authnreq = Net::SAML2::Protocol::AuthnRequest->new($maestrano->get_settings->get_saml_request_settings)->as_xml;

print $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
# Generate redirect
my $redirect = Net::SAML2::Binding::Redirect->new(
  url   => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
  cert  => $idp->cert('signing'),
  key   => $idp->cacert,
  param => 'SAMLRequest',
);

# # Generate URL
my $url = $redirect->sign($authnreq);

#print $url;
# 
# # Perform redirect
print $q->redirect($url);

# Confirm execution