
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::ISO8601;
use POSIX qw(strftime);
use Data::Dumper;
use strict;
use warnings;

package MnoSsoBaseUser;
use JSON qw( decode_json );

# my $iso8601_parser = DateTime::Format::Strptime->new(
#   pattern => '%B %d, %Y %I:%M %p %Z',
#   on_error => 'croak',
# );

# Constructor
# Arguments:
# => saml_response
# => session
sub new
{
  my $class = shift;
  
  my $saml_response = shift;
  my $session       = shift;
  
  my $assert_attrs = $saml_response->attributes;
  
  my $self = {
    session       => $session,
    uid           => $assert_attrs->{mno_uid}[0],
    sso_session   => $assert_attrs->{mno_session}[0],
    sso_session_recheck => DateTime::Format::ISO8601->parse_datetime($assert_attrs->{mno_session_recheck}[0]),
    name          => $assert_attrs->{name}[0],
    surname       => $assert_attrs->{surname}[0],
    email         => $assert_attrs->{email}[0],
    app_owner     => ($assert_attrs->{app_owner}[0] eq 'true'),
    organizations => decode_json($assert_attrs->{organizations}[0]),
  };
  
  bless($self, $class);
  
  return $self;
}

#
# Try to find a local application user matching the sso one
# using uid first, then email address.
# If a user is found via email address then then set_local_uid
# is called to update the local user Maestrano UID
# ---
# Internally use the following interface methods:
#  - get_local_id_by_uid
#  - get_local_id_by_email
#  - set_local_uid
#  - sync_local_details
# 
# Return local_id if a local user matched, null otherwise
#
sub match_local
{
  my ($self) = @_;
  
  # Try to get the local id from uid
  $self->{local_id} = $self->get_local_id_by_uid();
  
  # Get local id via email if previous search was unsucessful
  if (!defined($self->{local_id})) {
    $self->{local_id} = $self->get_local_id_by_email();
    
    # Set Maestrano UID on user
    if(defined($self->{local_id})) {
      $self->set_local_uid();
    }
  }
  
  # Sync local details if we have a match
  if(defined($self->{local_id})) {
    $self->sync_local_details();
  }
  
  return $self->{local_id};
}

#
# Return whether the user is private (
# local account or app owner or part of
# organization owning this app) or public
# (no link whatsoever with this application)
#
# Return 'public' or 'private'
#
sub access_scope
{
  my ($self) = @_;
  
  if ($self->{local_id} || $self->{app_owner} || scalar(keys %$self->organization) > 0) {
    return 'private';
  }
  
  return 'public';
}

#
# Create a local user by invoking create_local_user
# and set uid on the newly created user
# If create_local_user returns null then access
# is refused to the user
#
sub create_local_user_or_deny_access
{
  my ($self) = @_;
  
  if (!defined($self->{local_id})) {
   $self->{local_id} = $self->create_local_user();

    # If a user has been created successfully
    # then make sure UID is set on it
    if ($self->{local_id}) {
      $self->set_local_uid();
    }
 }
 
 return $self->{local_id};
}

#
# Create a local user based on the sso user
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
sub create_local_user
{
  my ($self) = @_;
  die 'Function '. (caller(0))[3] . ' must be overriden in MnoSsoUser class!';
}

#
# Get the ID of a local user via Maestrano UID lookup
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
sub get_local_id_by_uid
{
  my ($self) = @_;
  die 'Function '. (caller(0))[3] . ' must be overriden in MnoSsoUser class!';
}

#
# Get the ID of a local user via email lookup
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
sub get_local_id_by_email
{
  my ($self) = @_;
  die 'Function '. (caller(0))[3] . ' must be overriden in MnoSsoUser class!';
}

#
# Set the Maestrano UID on a local user via email lookup
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
sub set_local_uid
{
  my ($self) = @_;
  die 'Function '. (caller(0))[3] . ' must be overriden in MnoSsoUser class!';
}

#
# Set all 'soft' details on the user (like name, surname, email)
# This is a convenience method that must be implemented in
# MnoSsoUser but is not mandatory.
#
# Return boolean whether the user was synced or not
#
sub sync_local_details
{
  my ($self) = @_;
  die 'Function '. (caller(0))[3] . ' must be overriden in MnoSsoUser class!';
}

#
# Sign the user in the application. By default,
# set the mno_uid, mno_session and mno_session_recheck
# in session.
# It is expected that this method get extended with
# application specific behavior in the MnoSsoUser class
#
# Return boolean whether the user was successfully signedIn or not
#
sub sign_in
{
  my ($self) = @_;
  if ($self->set_in_session()) {
    # ISO8601 Date Formating
    # We need to munge the timezone indicator to add a colon between the hour and minute part
    my $tz = strftime("%z", localtime(time()));
    $tz =~ s/(\d{2})(\d{2})/$1:$2/;
    my $iso8601_recheck = strftime("%Y-%m-%dT%H:%M:%S", $self->{sso_session_recheck}) . $tz;
    
    $self->{session}->param('mno_uid',$self->{uid});
    $self->{session}->param('mno_session', $self->{sso_session});
    $self->{session}->param('mno_session_recheck',$iso8601_recheck);
  }
}

#
# Generate a random password.
# Convenient to set dummy passwords on users
#
# Return string a random password
#
sub generate_password
{
  my ($self) = @_;
  my $length = 20;
  my @characters = split('','0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');
  my $randomString = '';
  
  for (my $i = 0; $i < $length; $i++) {
      $randomString .= $characters[rand(scalar(@characters))];
  }
  return $randomString;
}

#
# Set user in session. Called by sign_in method.
# This method should be overriden in MnoSsoUser to
# reflect the app specific way of putting an authenticated
# user in session.
#
# Return boolean whether the user was successfully set in session or not
#
sub set_in_session
{
  my ($self) = @_;
  die 'Function '. (caller(0))[3] . ' must be overriden in MnoSsoUser class!';
}

1;