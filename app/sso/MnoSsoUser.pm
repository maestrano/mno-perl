use strict;
use warnings;

package MnoSsoUser;
use MnoSsoBaseUser;

our @ISA = qw(MnoSsoBaseUser);    # inherits from MnoSsoBaseUser

# 
# Contructor
# Takes the following arguments:
# - saml_response
# - session
# - opts (hash of options)
sub new
{
  my ($class, $saml_response,$session,$opts) = @_;
  
  my $self = $class->SUPER::new($saml_response, $session);
  
  # Define connection
  $self->{connection} = $opts->{connection};
  
  bless($self, $class);
  return $self;
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
  
  # Grab the user first
  my $user = new Bugzilla::User($self->{local_id});
  
  if($user) {
    my $cookie = new Bugzilla::Auth::Persist::Cookie();
    
    # Put the user in session
    $cookie->persist_login($user);
    
    return 1;
  }
  
  return;
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
  
  my $lid;
  
  if ($self->access_scope() eq 'private') {
    # Create the bugzilla user
    my $user = Bugzilla::User->create($self->build_local_user());
    
    # Get the id
    $lid = $user->id;
    
    # Generate the permissions
    if ($lid) {
      $self->generate_app_permissions($user);
    }
  }
  
  return $lid;
}

#
# Build a local user for creation
#
# Return a user or hash of attributes
#
sub build_local_user
{
  my ($self) = @_;
  
  my $user = { 
    login_name    => $self->{email}, 
    realname      => $self->{name} . ' ' . $self->{surname}, 
    cryptpassword => $self->generate_password(), 
    disabledtext  => '',
    disable_mail  => 0
  };
  
  return $user;
}

sub generate_app_permissions
{
  my ($self,$user) = @_;
  
  my @permissions = $self->get_user_permissions();
  
  my $sth_add_mapping = $self->{connection}->prepare(
    qq{INSERT INTO user_group_map (
              user_id, group_id, isbless, grant_type
             ) VALUES (
              ?, ?, ?, ?
             )
  });
  
  
  foreach (@permissions) {
      my $group_id = $_;
      
      # Add permissions
      $sth_add_mapping->execute($user->id, $group_id, 0, 0);
      $sth_add_mapping->execute($user->id, $group_id, 1, 0);
  }
}

#
# Return a permissions hash based on user profile
# If the user is the app owner or admin for all organizations
# owning this app then the user will be given full admin rights
# Otherwise the user gets basic rights
#
# Returns a hash of permissions
#
sub get_user_permissions 
{
  my ($self) = @_;
  
  my @default_user_permissions = ();
  
  # Get the IDs of all groups
  my @default_admin_permissions = ();
  my $sth = $self->{connection}->prepare("SELECT id FROM groups");
  $sth->execute;
  
  my @result = ();
  while (@result = $sth->fetchrow_array) {
    push(@default_admin_permissions, $result[0]);
  }
  use Data::Dumper;
  print Dumper(@default_admin_permissions);
  
  # Initialize permissions 
  my @permissions = @default_user_permissions; # User
  
  if ($self->{app_owner}) {
    @permissions = @default_admin_permissions; # Admin
  } else {
    foreach ($self->{organizations}) {
      my $organization = $_;
      
      if ($organization->{role} eq 'Admin' || $organization->{role} eq 'Super Admin') {
        @permissions = @default_admin_permissions;
      } else {
        @permissions = @default_user_permissions;
      }
    }
  }
  
  return @permissions;
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
  
  my $sth = $self->{connection}->prepare("SELECT userid FROM profiles WHERE mno_uid = ? LIMIT 1");
  $sth->bind_param(1,$self->{uid});
  
  # Execute the query and get get the results
  $sth->execute;
  my @result = $sth->fetchrow_array;
  my $result = $result[0];
  
  if ($result && $result[0]) {
    return $result[0];
  }
  
  return;
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
  
  my $sth = $self->{connection}->prepare("SELECT userid FROM profiles WHERE login_name = ? LIMIT 1");
  $sth->bind_param(1,$self->{email});
  
  # Execute the query and get get the results
  $sth->execute;
  my @result = $sth->fetchrow_array;
  my $result = $result[0];
  
  if ($result && $result->{userid}) {
    return $result->{userid};
  }
  
  return;
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
  
  if ($self->{local_id}) {
    
    my $sth = $self->{connection}->prepare("UPDATE profiles 
      SET login_name = ?,
      realname = ?
      WHERE userid = ? LIMIT 1");
    $sth->bind_param(1,$self->{email});
    $sth->bind_param(2,$self->{name} . ' ' . $self->{surname});
    $sth->bind_param(3,$self->{local_id});
  
    # Execute the query and get get the results
    my $upd = $sth->execute;
  
    return $upd;
  }
  
  return;
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
  
  if ($self->{local_id}) {
    
    my $sth = $self->{connection}->prepare("UPDATE profiles 
      SET mno_uid = ?
      WHERE userid = ? LIMIT 1");
    $sth->bind_param(1,$self->{uid});
    $sth->bind_param(2,$self->{local_id});
  
    # Execute the query and get get the results
    my $upd = $sth->execute;
  
    return $upd;
  }
  
  return;
}



