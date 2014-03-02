use strict;
use warnings;
use CGI::Session;

package MaestranoService;

my $service_instance;
my $settings;
my $default_after_sso_sign_in_path = '/';

# Provide the instance of MaestranoService
sub instance {
  $service_instance ||= (shift)->new();
}

# Set the settings that should be
# used.
# Parameter should be an instance of MnoSettings
sub configure {
  my $class = shift;
  $settings = shift;
}

# Constructor
sub new {
  my $class = shift;
  my $self = {
    settings               => $settings,
    after_sso_sign_in_path => $default_after_sso_sign_in_path,
  };
  
  
  bless($self, $class);
  return $self;
}

#
# Return the maestrano settings
#
# Return MnoSsoSession
#/
sub get_settings
{
  my ($self) = @_;
  
  return $self->{settings};
}

#
# Return the server session
#
# Return MnoSsoSession
#/
sub get_session
{
  my ($self) = @_;
  
  my $sid = CGI->new->cookie("CGISESSID") || undef;
  my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
  return $session;
}

#
# Return the maestrano sso session
#
# Return MnoSsoSession
#/
sub get_sso_session
{
  my ($self) = @_;
  
  return (new MnoSsoSession($self->{settings}, $self->get_session()));
}

#
# Check if Maestrano SSO is enabled
#
# Return boolean
#/
sub is_sso_enabled
{
  my ($self) = @_;
  
  return ($self->{settings} && $self->{settings}->{sso_enabled});
}

#
# Return wether intranet sso mode is enabled (no public pages)
#
# Return boolean
#/
sub is_sso_intranet_enabled
{
  my ($self) = @_;
  
  return ($self->is_sso_enabled() && $self->{settings}->{sso_intranet_mode});
}

#
# Return where the app should redirect internally to initiate
# SSO request
#
# Return boolean
#/
sub get_sso_init_url
{
  my ($self) = @_;
  
  return $self->{settings}->{sso_init_url};
}

#
# Return where the app should redirect after logging user
# out
#
# Return string url
#/
sub get_sso_logout_url
{
  my ($self) = @_;
  
  return $self->{settings}->{sso_access_logout_url};
}

#
# Return where the app should redirect if user does
# not have access to it
#
# Return string url
#/
sub get_sso_unauthorized_url
{
  my ($self) = @_;
  
  return $self->{settings}->{sso_access_logout_url};
}

#
# Set the after sso signin path
#
# Return string url
#/
sub set_after_sso_sign_in_path
{
  my ($self,$path) = @_;
  
  if ($self->get_session()) {
	  my $session = $self->get_session();
    $session->param('mno_previous_url', $path);
  }
}

#
# Return the after sso signin path
#
# Return string url
#/
sub get_after_sso_sign_in_path
{
  my ($self) = @_;
  
  return $self->{after_sso_sign_in_path};
}

