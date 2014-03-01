use strict;
use warnings;

package MnoSettings;

#
# The name of the application.
# @var string
#
my $app_name = 'myapp';

#
# Is SSO enabled for this application
# @var boolean
#
my $sso_enabled = 0;

#
# If enabled then  access will be completely
# denied (ALL pages will require authentication)
# @var boolean
#
my $sso_intranet_mode = 0;

#
# Maestrano Single Sign On url
# @var string
#
my $sso_url = '';

#
# The URL where the SSO request should be initiated.
# @var string
#
my $sso_init_url = '';

#
# The URL where the SSO response will be posted.
# @var string
#
my $sso_return_url = '';

#
# The URL where the application should redirect if
# user is not given access.
# @var string
#
my $sso_access_unauthorized_url = '';

#
# The URL where the application should redirect when
# user logs out
# @var string
#
my $sso_access_logout_url = '';

#
# The x509 certificate used to authenticate the request.
# @var string
#
my $sso_x509_certificate = '';

# Path to the CA cert
# String
my $sso_cacert_path = '';

#
# Specifies what format to return the identification token (Maestrano user UID)
# @var string
#
my $sso_name_id_format = 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent';

#
# The Maestrano endpoint in charge of providing session information
# @var string
#
my $sso_session_check_url = '';

# Constructor
sub new 
{
  my $class = shift;
  
  my $self = {
    app_name                    => $app_name,
    sso_enabled                 => $sso_enabled,
    sso_intranet_mode           => $sso_intranet_mode,
    sso_url                     => $sso_url,
    sso_init_url                => $sso_init_url,
    sso_return_url              => $sso_return_url,
    sso_access_unauthorized_url => $sso_access_unauthorized_url,
    sso_access_logout_url       => $sso_access_logout_url,
    sso_x509_certificate        => $sso_x509_certificate,
    sso_name_id_format          => $sso_name_id_format,
    sso_session_check_url       => $sso_session_check_url,
    sso_cacert_path             => $sso_cacert_path
  };
  
  bless($self, $class);
  return $self;
}

# Return a settings object for Net::SAML2::Idp
sub get_saml_idp_settings
{
  my ($self) = @_;
  
  return {
    entityid => 'Maestrano',
    cacert => $self->{sso_cacert_path},
    certs => { 'signing' => $self->{sso_x509_certificate} },
    sso_urls => { 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect' => $self->{sso_url} },
    slo_urls => {},
    art_urls => {},
    default_format => $self->{sso_name_id_format},
    formats => {}
  };
}

# Return a settings object for the SAML request
sub get_saml_request_settings
{
  my ($self) = @_;
  
  return (
    issuer        => $self->{app_name},
    destination   => URI->new($self->{sso_return_url}),
    nameid_format => $self->{sso_name_id_format},
    );
}

1;
