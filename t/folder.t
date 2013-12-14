#!/usr/bin/perl
use Test::More tests => 6;

BEGIN { use_ok('Net::Box::Folder'); }

my $fs;
ok( $fs = Net::Box::Folder->new, 'Filesystem created' );
my $name = '__test__'.time;
ok( $fs->create_folder( $name ), "Creating folder $name" );
ok( $fs->find( $name ), 'Searching for new folder' );
ok( $fs->delete_folder( $name ), "Deleting folder $name" );
ok( $fs->find( $name ) == undef, 'Searching for deleted folder' );
