package Net::Box::Transport::LWPTransport;
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper qw/ Dumper /;

sub new {
	my $proto = shift;
	my %args = @_;
	my $self = {};
	my $class = ref $proto || $proto;
	bless $self, $proto;
	$self->{api_key} = $args{api_key};
	$self->{ua} = LWP::UserAgent->new;
	$self->login;
	return $self;
}

sub login {
	my $self = shift;
=pod
	my $response = $self->{ua}->get( "https://www.box.com/api/1.0/rest?action=get_ticket&api_key=$self->{api_key}" );
	my ( $ticket ) = $response->decoded_content =~ m|<ticket>(.+)</ticket>|;
	`sudo -u ackap chromium-browser 'https://www.box.com/api/1.0/auth/$ticket'`;

	#print STDERR "Waiting for authorization...\n";
	do {
		sleep 3;
		$response = $self->{ua}->get("https://www.box.com/api/1.0/rest?action=get_auth_token&api_key=$self->{api_key}&ticket=$ticket" );
		#print $response->decoded_content ."\n";
	} while index( $response->decoded_content, '<status>get_auth_token_ok</status>') == -1;

	$self->{auth_token} = $response->decoded_content =~ m|<auth_token>(.*)</auth_token>|;
=cut
	$self->{auth_token} = '9g3y4opnndihlugxb1ppetul0os6s3ka';
	$self->{ua}->default_header( 
	  Authorization => "BoxAuth api_key=$self->{api_key}&auth_token=$self->{auth_token}"
	);
}

sub get_dir_info {
	my ( $self, $dir_id ) = @_;
	#print "Net::Box::get_dir_info( '$dir_id' )\n";
	#print "Requesting...\n";
	my $response = $self->{ua}->get("https://api.box.com/2.0/folders/$dir_id");
	##print "Response: " . Dumper($response) unless $response;
	my $info = decode_json( $response->decoded_content );
	##print "Transport received:\n";
	##print Dumper( decode_json $response->decoded_content );
	#print "Result: " . Dumper( $self->{dir_info_cache}->{$dir_id} );
	return $info;
}
=pod
Example Response

{
    "type":"folder",
    "id":"291539343",
    "sequence_id":"0",
    "name":"My great folder",
    "created_at":"2012-05-25T14:51:19-07:00",
    "modified_at":"2012-06-08T10:56:17-07:00",
    "description":"this is a pretty good folder",
    "size":2301,
    "created_by":
    {
        "type":"user",
        "id":"13344957",
        "name":"Sean Rose",
        "login":"sean@emailprovider.com"
    },
    "modified_by":
    {
        "type":"user",
        "id":"13344957",
        "name":"Sean Rose",
        "login":"sean@emailprovider.com"
    },
    "owned_by":
    {
        "type":"user",
        "id":"13344957",
        "name":"Sean Rose",
        "login":"sean@emailprovider.com"
    },
    "parent":
    {
        "type":"folder",
        "id":"0",
        "sequence_id":null,
        "name":"All Files"
    },
    "item_collection":
    {
        "total_count":2,
        "entries":[
            {
                "type":"file",
                "id":"2305649799",
                "sequence_id":"1",
                "name":"testing.html"
            },
            {
                "type":"folder",
                "id":"2305623799",
                "sequence_id":"1",
                "name":"a child folder"
            }
        ]
    }
}

=cut

=pod
Example File

{
    "type":"file",
    "id":"2192049121",
    "sequence_id":"1",
    "name":"stayhungry_stayfoolish.psd",
    "description":"",
    "size":1266400,
    "path":"\/stayhungry_stayfoolish.psd",
    "path_id":"\/0\/2192049121",
    "created_at":"2012-06-04T21:32:20-07:00",
    "modified_at":"2012-06-04T21:32:21-07:00",
    "shared_link_enabled":false,
    "shared_link":null,
    "sha1":"72e96dad26aa67a5f7435548c86b7a8a331f0ae9",
    "created_by":
    {
        "type":"user",
        "id":"13344957",
        "name":"Sean Rose",
        "login":"sean+test@box.com"
    },
    "modified_by":
    {
        "type":"user",
        "id":"13344957",
        "name":"Sean Rose",
        "login":"seanrose@stanford.edu"
    },
    "owned_by":
    {
        "type":"user",
        "id":"13344957",
        "name":"Sean Rose",
        "login":"seanrose@stanford.edu"
    },
    "parent":
    {
        "type":"folder",
        "id":"0",
        "sequence_id":null,
        "name":"All Files"
    }
}
=cut
sub get_file_info {
	my ( $self, $file_id ) = @_;
	#print "Net::Box::get_file_info( '$file_id' )\n";
	#print "Requesting...\n";
	my $response = $self->{ua}->get("https://api.box.com/2.0/files/$file_id");
	my $info = decode_json( $response->decoded_content );
	#print "Result: " . Dumper( $self->{file_info_cache}->{$file_id} );
	return $info;
}

sub get_dir_items {
	my ( $self, $dir_id ) = @_;
	my $response = $self->{ua}->get("https://api.box.com/2.0/folders/$dir_id/items");
	decode_json( $response->decoded_content );
}
=pod
{
    "total_count":1,
    "entries":[
        {
            "type":"file",
            "id":"2305649799",
            "sequence_id":"1",
            "name":"testing.html"
        }
    ]
}
=cut
1;
