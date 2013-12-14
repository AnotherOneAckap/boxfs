package Net::Box::Folder;
use Path::Abstract qw/--no_0_093_warning/;
use strict;
#use warnings;
use Net::Box::Transport::FurlTransport;
use Net::Box::File;
use DateTime::Format::ISO8601;
use Data::Dumper qw/Dumper/;
$Data::Dumper::Maxdepth = 2;

=for TODO

Надо сделать два кеша, 
первый только путь и ид будет кешировать, 
второй будет кешировать сами объекты по ид.
Тогда полученный через гет объект можно быстренько запихнуть во второй кеш, пропуская lookup.
А так приходится всё равно искать, куда приткнуть полученный объект.

=cut

=head2 new( %args )

Creates new folder object, possible arguments:
	B<id>   folder id in box cloud
	B<path> folder absolute path
	B<name> folder name

=cut

sub new {
	my ( $proto, %args ) = @_;
	my $class = ref $proto || $proto;
	my $self = {};
	bless $self, $class;
	$self->{id}   = $args{id} || 0;	
	$self->{path} = $args{path} || '/';
	$self->{name} = $args{name} || '';
	$self->{transport} = $args{transport} || Net::Box::Transport::FurlTransport->new( api_key => '' );#TODO
	return $self;
}

sub is_cache_valid {
	return 1;
	return time - $_[0]->{_fetched} < 1800;
}

sub name()      { $_[0]->{name} }
sub id()        { $_[0]->{id} }
sub transport() { $_[0]->{transport} }
sub path()      { $_[0]->{path} }

=head2 get( I<$folder_id> )

Returns folder with given id.

=cut

sub get {
	my ( $self, $folder_id ) = @_;
	return $self->{folder_cache}->{$folder_id} 
	  if exists $self->{folder_cache}->{$folder_id} && $self->is_cache_valid( $folder_id );
	my $folder = __PACKAGE__->new( id => $folder_id );
	$folder->info;
	return $folder;
}

=head2 info( )

Returns hash with information about this folder, timestamps all are in unixtime.

=cut

sub info {
	my ( $self ) = @_;

	return $self->{info} if $self->{info} && $self->is_cache_valid; 

	my $info;
	$info = $self->{transport}->get_dir_info( $self->{id} );
	$info->{created_at}  = DateTime::Format::ISO8601->parse_datetime( $info->{created_at}  )->epoch if $info->{created_at} =~ /T/; 
	$info->{modified_at} = DateTime::Format::ISO8601->parse_datetime( $info->{modified_at} )->epoch if $info->{modified_at} =~ /T/; 
	$self->{info} = $info;
	$self->{_fetched} = time;
	return $info;
}

sub items {
	my ( $self ) = @_;

	return values $self->{items} if $self->{items} && $self->is_cache_valid;

	my %items = ();
	my $collection = $self->{transport}->get_dir_items( $self->{id} );
	for my $entry ( @{ $collection->{entries} } ) {
		my $item;
		$item = Net::Box::File->new( 
			id        => $entry->{id},
			name      => $entry->{name},
			transport => $self->{transport},
			path      => $self->{path} eq '/' ? '/'.$entry->{name} : $self->{path}.'/'.$entry->{name}
		) if $entry->{type} eq 'file';

		$item = Net::Box::Folder->new(
			id        => $entry->{id}, 
			name      => $entry->{name}, 
			transport => $self->{transport}, 
			path      => $self->{path} eq '/' ? '/'.$entry->{name} : $self->{path}.'/'.$entry->{name}
		) if $entry->{type} eq 'folder';

		next unless $item;
		$items{$item->id} = $item;
	}
	$self->{items} = \%items;
	return values %items; 
}

sub find {
	my ( $self, $path ) = @_;
	return $self if $self->name eq '.';
	my @node_list = Path::Abstract->new( $path )->list;
	my $next = shift @node_list;
	$path = Path::Abstract->new( @node_list )->stringify;

	return $self if ($self->name eq $next) && ! $path;
	my @items = $self->items;
	for my $item ( @items ) {
		return $item if ($item->name eq $next) && ! $path;
		return $item->find( $path ) if $item->name eq $next;	
	}
	return undef;
}

sub find_abs {
	my ( $self, $path ) = @_;
	#TODO
	return $self if $path eq $self->{path};	
	my ( $filename ) = $path =~ m|.*/(.+)$|;
	my @items = $self->items;
	for my $item ( @items ) {
		return $item if $item->name eq $filename;
	}
	for my $item ( @items ) {
		my $res;
		return $res if ref $item eq 'Net::Box::Folder' && ( $res = $item->find( $path ) );
	}
	return undef;
}

sub create_folder {
	my ( $self, $name ) = @_;
	# create folder in cloud
	my $new_folder_info = $self->{transport}->create_folder( $self->id, $name );
	# retrieve items to refresh content
	$new_folder_info->{created_at}  = DateTime::Format::ISO8601->parse_datetime( $new_folder_info->{created_at}  )->epoch if $new_folder_info->{created_at} =~ /T/; 
	$new_folder_info->{modified_at} = DateTime::Format::ISO8601->parse_datetime( $new_folder_info->{modified_at} )->epoch if $new_folder_info->{modified_at} =~ /T/; 
	my $new_folder = Net::Box::Folder->new( $new_folder_info, path => $self->path .'/'.$name, transport => $self->transport );
}

=head2 delete_folder( $name )

Deletes subfolder with given name
Returns 1 on success, undef on failure.

=cut
sub delete_folder {
	my ( $self, $name ) = @_;
	
	my $folder_to_delete = $self->find( $name );
	# delete folder in cloud
	if ( $self->{transport}->delete_folder( $folder_to_delete->id ) ) {
	# delete folder in filesystem
		delete $self->{items}->{$folder_to_delete->id};
		return 1;
	}
	return undef;
}
1;
