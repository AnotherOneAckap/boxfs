package Net::Box::Transport::FurlTransport;
use strict;
use warnings;
use Furl;
use JSON;
use Data::Dumper qw/ Dumper /;

sub new {
	my $proto = shift;
	my %args = @_;
	my $self = {};
	my $class = ref $proto || $proto;
	bless $self, $proto;
	$self->{api_key} = $args{api_key};
	$self->login;
	return $self;
}

sub login {
	my $self = shift;
=for development_puposes_only
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
	$self->{ua} = Furl->new( 
	  headers => [ Authorization => "BoxAuth api_key=$self->{api_key}&auth_token=$self->{auth_token}" ]
	);
}

sub get_dir_info {
	my ( $self, $dir_id ) = @_;
	#print "Net::Box::get_dir_info( '$dir_id' )\n";
	#print "Requesting...\n";
	my $response = $self->{ua}->get("https://api.box.com/2.0/folders/$dir_id");
	##print "Response: " . Dumper($response) unless $response;
	my $info = decode_json( $response->content );
	##print "Transport received:\n";
	##print Dumper( decode_json $response->decoded_content );
	#print "Result: " . Dumper( $self->{dir_info_cache}->{$dir_id} );
	return $info;
}
=for example
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

=for example
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
	my $info = decode_json( $response->content );
	#print "Result: " . Dumper( $self->{file_info_cache}->{$file_id} );
	return $info;
}

sub get_dir_items {
	my ( $self, $dir_id ) = @_;
	my $response = $self->{ua}->get("https://api.box.com/2.0/folders/$dir_id/items");
	decode_json( $response->content );
}

sub create_folder {
	my ( $self, $parent_id, $name ) = @_;
	my $response = $self->{ua}->post("https://api.box.com/2.0/folders/$parent_id", [], encode_json( { name => $name } ) );
	my $res = decode_json( $response->content );
	die Dumper( $res ) if $res->{type} eq 'error';
	return $res;
}

=head2 delete_folder( %args )

Used to delete a folder. A force parameter must be included in order to delete

	force => boolean Whether to delete this folder if it has items inside of it

Returns
1 if success
An error is thrown if the folder is not empty and the ‘force’ parameter is not included.

=cut
sub delete_folder {
	my ( $self, $folder_id, %args ) = @_;
	my $response = $self->{ua}->delete( "https://api.box.com/2.0/folders/".$folder_id );
	die Dumper( $response->content ) if $response->content;# successful request returns empty

	return 1;
}
=for example
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

=for example
{
	"type":"folder",
	"id":"0",
	"sequence_id":null,
	"name":"All Files",
	"created_at":null,
	"modified_at":null,
	"description":null,
	"size":604589167,
	"created_by": {
		"type":"user",
		"id":"16218010",
		"name":"Ackap AnotherOne",
		"login":"anotheroneackap@gmail.com"
	},
	"modified_by": {
		"type":"user",
		"id":"16218010",
		"name":"Ackap AnotherOne",
		"login":"anotheroneackap@gmail.com"
	},
	"owned_by": {
		"type":"user",
		"id":"16218010",
		"name":"Ackap AnotherOne",
		"login":"anotheroneackap@gmail.com"
	},
	"shared_link":null,
	"parent":null,
	"item_collection": {
		"total_count":4,
		"entries": [ 
			{
				"type":"folder",
				"id":"248783203",
				"sequence_id":"0",
				"name":"Anton Ernezaks and Friends live @ Tishina 30.03.2012"
			},
			{
				"type":"folder",
				"id":"199652138",
				"sequence_id":"0",
				"name":"prague"
			},
			{
				"type":"file",
				"id":"2379885716",
				"sequence_id":"0",
				"name":"IMAG0040.jpeg"
			},
			{
				"type":"file",
				"id":"2397620392",
				"sequence_id":"0",
				"name":"ticket_me_STRUCTURE_ID=14&layer_id=4945&refererLayerId=4985&ORDER_ID=34864693"
			}
			]
	}
}
=cut

=for example
<?xml version='1.0' encoding='UTF-8' ?>
<response>
<status>get_auth_token_ok</status>
<auth_token>5mzrmg4cqun80c07jb2hsazliln1y2b2</auth_token>
<user>
	<login>anotheroneackap@gmail.com</login>
	<email>anotheroneackap@gmail.com</email>
	<access_id>16218010</access_id>
	<user_id>16218010</user_id>
	<space_amount>53687091200</space_amount>
	<space_used>604589167</space_used>
	<max_upload_size>104857600</max_upload_size>
	<sharing_disabled/>
</user>
</response>
=cut
