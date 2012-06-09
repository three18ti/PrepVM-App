#!/usr/bin/perl

use strict;
use warnings;

use Sys::Guestfs;

use Config::Any;


use lib './lib';
use PrepVM::App;

# load the VM config
my $config = $ARGV[0];
my $cfg = Config::Any->load_files({ files => [$config], use_ext => 1 })->[0]->{$config};
my $vm = PrepVM::App->new( $cfg );

# create the virtual machine
chdir $vm->machine_path;



# mount the machine image
my $h = Sys::Guestfs->new;

$h->add_drive_opts( $vm->image_path, format => $vm->image_format );
$h->launch;

$h->mount_options('', '/dev/vda1', '/');

$h->write('/etc/network/interfaces', $vm->network_template);
$h->write('/etc/hostname', $vm->hostname);
$h->write('/etc/hosts', $vm->hosts_template);
