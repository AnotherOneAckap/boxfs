package BoxFS;
use warnings;
use strict;
use Net::Box::Transport::FurlTransport;
use Net::Box::Folder;
use base qw(Fuse::Class);
use Data::Dumper qw/ Dumper /;
use Fcntl ':mode';
use Errno ':POSIX';

sub new {
	my ( $proto, @args ) = @_;
	my $self = $proto->SUPER::new( @args );
	$self->{_fs} = Net::Box::Folder->new;
	return $self;
}

=pod
Arguments: filename. 
Returns a list, very similar to the 'stat' function (see perlfunc). On error, simply return a single numeric scalar value (e.g. "return -ENOENT();").
 0 dev      device number of filesystem
 1 ino      inode number
 2 mode     file mode  (type and permissions)
 3 nlink    number of (hard) links to the file
 4 uid      numeric user ID of file's owner
 5 gid      numeric group ID of file's owner
 6 rdev     the device identifier (special files only)
 7 size     total size of file, in bytes
 8 atime    last access time in seconds since the epoch
 9 mtime    last modify time in seconds since the epoch
10 ctime    inode change time (NOT creation time!) in seconds
            since the epoch
11 blksize  preferred block size for file system I/O
12 blocks   actual number of blocks allocated
=cut
sub getattr {
	my ( $self, $path ) = @_;
	#print "BoxFS::getattr('$path')\n";
	my $item = $self->{_fs}->find( $path );
	return -ENOENT() unless $item;
	my $info = $item->info;
	if ( ref $item eq 'Net::Box::Folder' ) {
		return ( 0, 0, ( S_IFDIR | 0700 ), 2 + $info->{item_collection}->{total_count}, 0, 0, 0, $info->{size}, 0, $info->{modified_at}, 0, 0, 0 );
	}
	if ( ref $item eq 'Net::Box::File' ) {
		return ( 0, 0, ( S_IFREG | 0700 ), 1, 0, 0, 0, $info->{size}, 0, $info->{modified_at}, 0, 0, 0 );
	}
}

# returns ([1, '..', [array_like_getattr]], [2, '.', [array_like_getattr]], 0)
sub readdir {
	my ( $self, $path, $offset, $handle ) = @_;
	$offset ||= 0;
	print "BoxFS::readdir( '". $_[1] . "', " . $_[2] ." )\n";
	my $dir = $self->{_fs}->find( $path );
	my @items = $dir->items;
	my @result;
	for ( my $i = $offset; $i <= $#items; $i++ ) {
		push @result, [ 1, '.' ], [ 2, '..' ] unless @result;
		my $item = $items[$i];
		my $info = $item->info;
		my @attrs;
		if ( ref $item eq 'Net::Box::Folder' ) {
			@attrs = ( 0, 0, ( S_IFDIR | 0700 ), 2 + $info->{item_collection}->{total_count}, 0, 0, 0, $info->{size}, 0, $info->{modified_at}, 0, 0, 0 );
		}
		if ( ref $item eq 'Net::Box::File' ) {
			@attrs = ( 0, 0, ( S_IFREG | 0700 ), 1, 0, 0, 0, $info->{size}, 0, $info->{modified_at}, 0, 0, 0 );
		}
		push @result, [ $i+3, $item->name, \@attrs ];
	}
	return (  @result, 0 );
}

sub rmdir {
	my ( $self, $path ) = @_;
	print "BoxFS::rmdir( '$path' )\n";
	return 0 if $self->{_fs}->delete_folder( $path );
	return EIO();
}

=item2 opendir(DIRECTORY_NAME)

Return an errno, and a directory handle (optional).

This method is called to open a directory for reading. If special handling is required to open a directory, this method can be implemented.

Supported by Fuse version 2.3 or later.
=cut
sub __opendir {
	my ( $self, $path ) = @_;
	print "BoxFS::opendir('$path')\n";
	my $folder = $self->{_fs}->find($path);
	my @result = $folder ? ( 0, $folder->id ) : ( ENOENT() );
	return @result;
}
1;
=pod
 0 dev      device number of filesystem
 1 ino      inode number
 2 mode     file mode  (type and permissions)
 3 nlink    number of (hard) links to the file
 4 uid      numeric user ID of file's owner
 5 gid      numeric group ID of file's owner
 6 rdev     the device identifier (special files only)
 7 size     total size of file, in bytes
 8 atime    last access time in seconds since the epoch
 9 mtime    last modify time in seconds since the epoch
10 ctime    inode change time (NOT creation time!) in seconds
            since the epoch
11 blksize  preferred block size for file system I/O
12 blocks   actual number of blocks allocated
=cut
