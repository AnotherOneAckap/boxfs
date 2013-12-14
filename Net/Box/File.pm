package Net::Box::File;

sub new {
	my ( $proto, %args ) = @_;
	my $class = ref $proto || $proto;
	my $self = {};
	bless $self, $class;
	$self->{id}   = $args{id} || 0;	
	$self->{dir} = $args{dir} || Net::Box::Folder->new;#TODO
	$self->{name} = $args{name};
	$self->{path} = $args{path};
	$self->{transport} = $args{transport} || Net::Box->new( api_key => '' );#TODO
	return $self;
}

sub name { $_[0]->{name} }
sub id { $_[0]->{id} }

sub is_cache_valid {
	return time - $self->{_fetched} < 1800;
}

sub info {
	my ( $self ) = @_;

	return $self->{info} if $self->{info} && $self->is_cache_valid; 

	print "Net::Box::File::info() requests data\n";
	my $info = $self->{transport}->get_file_info( $self->{id} );
	$info->{created_at}  = DateTime::Format::ISO8601->parse_datetime( $info->{created_at}  )->epoch if $info->{created_at} =~ /T/; 
	$info->{modified_at} = DateTime::Format::ISO8601->parse_datetime( $info->{modified_at} )->epoch if $info->{modified_at} =~ /T/; 
	$self->{info} = $info;
	$self->{_fetched} = time;
	print "Net::Box::File::info() requested data\n";
	return $info;
}
1;
