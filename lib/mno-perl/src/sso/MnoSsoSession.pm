use JSON qw( decode_json );
use DateTime;
use LWP::Simple;
use strict;
use warnings;

package MnoSsoSession;

#
# Construct the MnoSsoSession object
#
# Param MnoSettings $mno_settings
#   A Maestrano Settings object
# Param Array $session
#   A session object, usually $_SESSION
#
#
sub new
{
  my $class = shift;
  
  my $mno_settings = shift;
  my $session      = shift;
  
  # Populate attributes from params
  $self = {
    settings => $mno_settings,
    session  => $session,
    uid      => $session->param('mno_uid'),
    token    => $session->param('mno_session'),
    recheck  => DateTime::Format::HTTP->parse_datetime($session->param('mno_session_recheck')),
  };
  
  return $self;
}

#
# Check whether we need to remotely check the
# session or not
#
# Return boolean
#
sub remote_check_required
{
  my ($self) = @_;
  
  if (defined($self->{uid}) && defined($self->{token}) && defined($self->{recheck})) {
   if ($self->{recheck} > (DateTime->now)) {
     return undef;
   }
  }
 
 return 1;
}
 
#
# Return the full url from which session check
# should be performed
#
# Return string the endpoint url
#
sub session_check_url
{
  my ($self) = @_;
  
  my $url = $self->settings->sso_session_check_url . '/' . $self->uid . '?session=' . $self->token;
  return $url;
}

#
 # Fetch url and return content. Wrapper function.
 #
 # @param string full url to fetch
 # Return string page content
 #
sub fetch_url
{
  my ($self,$url) = @_;
  
  return get($url);
}
  
#
# Perform remote session check on Maestrano
#
# Return boolean the validity of the session
#
sub perform_remote_check 
{
  my ($self) = @_;
  
  my $json = $self->fetch_url($self->session_check_url());
 
  if ($json) {
    $response = decode_json($json);
  
    if ($response{'valid'} && $response{'recheck'}) {
      $self->recheck = DateTime::Format::HTTP->parse_datetime($response{'recheck'});
      return 1;
    }
  }
 
  return undef;
}

#
# Perform check to see if session is valid
# Check is only performed if current time is after
# the recheck timestamp
# If a remote check is performed then the mno_session_recheck
# timestamp is updated in session.
#
# Return boolean the validity of the session
#
sub is_valid 
{
  my ($self) = @_;
  
  if ($self->remote_check_required()) {
    if ($self->perform_remote_check()) {
      $self->session->param('mno_session_recheck',$self->recheck->format(DateTime::ISO8601));
      
      return 1;
    } else {
      return undef;
    }
  } else {
    return 1;
  }
}