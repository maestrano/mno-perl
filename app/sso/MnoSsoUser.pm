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
# sub set_in_session
# {
#   my ($self) = @_;
#   
# }

#
# Create a local user based on the sso user
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
# sub create_local_user
# {
#   my ($self) = @_;
#   die Exception->new('Function '. __LINE__ . ' must be overriden in MnoSsoUser class!');
# }

#
# Build a local user for creation
#
# Return a user or hash of attributes
#
# sub build_local_user
# {
#   my ($self) = @_;
#   die Exception->new('Function '. __LINE__ . ' must be overriden in MnoSsoUser class!');
# }

#
# Create the role to give to the user based on context
# If the user is the owner of the app or at least Admin
# for each organization, then it is given the role of 'Admin'.
# Return 'User' role otherwise
#
# Return the role id
#
# sub get_role_id_to_assign 
# {
#   my ($self) = @_;
#   
#   my $role_id = 2; # User
#   
#   if ($self->app_owner) {
#     $role_id = 1; # Admin
#   } else {
#     foreach ($self->organizations) {
#       my $organization = $_;
#       
#       if ($organization{'role'} eq 'Admin' || $organization{'role'} eq 'Super Admin') {
#         $role_id = 1;
#       } else {
#         $role_id = 2;
#       }
#     }
#   }
#   
#   return $role_id;
# }

#
# Get the ID of a local user via Maestrano UID lookup
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
# sub get_local_id_by_uid
# {
#   my ($self) = @_;
# }

#
# Get the ID of a local user via email lookup
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
# sub get_local_id_by_email
# {
#   my ($self) = @_;
# }

#
# Set the Maestrano UID on a local user via email lookup
# This method must be re-implemented in MnoSsoUser
# (raise an error otherwise)
#
# Return a user ID if found, null otherwise
#
# sub set_local_uid
# {
#   my ($self) = @_;
# }

#
# Set all 'soft' details on the user (like name, surname, email)
# This is a convenience method that must be implemented in
# MnoSsoUser but is not mandatory.
#
# Return boolean whether the user was synced or not
#
# sub sync_local_details
# {
#   my ($self) = @_;
# }

