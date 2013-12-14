use BoxFS;
use Data::Dumper qw/Dumper/;

my $fuse = BoxFS->new();
#print Dumper $fuse;
$| = 1;
#$fuse->main( debug => 1, mountpoint => '/mnt/sample', mountopts => "allow_other");
#$fuse->main( mountpoint => '/home/ackap/tmp/sample', mountopts => "allow_other");
$fuse->main( mountpoint => '/home/ackap/tmp/sample' );

# control will be not returned until file system is unmouted...
