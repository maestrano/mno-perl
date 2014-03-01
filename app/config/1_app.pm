# Get full host (protocal + server host)
my $protocol = (defined($ENV{'HTTPS'}) && $ENV{'HTTPS'} eq 'on') ? 'https://' : 'http://';
my $full_host = $protocol . $ENV{'HTTP_HOST'};

# Name of your application
$mno_settings->{app_name} = 'myapp';

# Enable Maestrano SSO for this app
$mno_settings->{sso_enabled} = 1;

# SSO initialization URL
$mno_settings->{sso_init_url} = $full_host . '/maestrano/auth/saml/index.cgi';

# SSO processing url
$mno_settings->{sso_return_url} = $full_host . '/maestrano/auth/saml/consume.cgi';

1;