#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Config::Any;

use lib './lib';
use PrepVM::App;

die "Please indicate a valid Machine Config\n"
    unless @ARGV;

# load the VM config
my $config = $ARGV[0];
my $cfg = Config::Any->load_files({ files => [$config], use_ext => 1 })->[0]->{$config};
my $vm = PrepVM::App->new( $cfg );

unlink $vm->image_path;
die "Image: " . $vm->image_path 
    . "\nAlready Exists, please remove before continuing\n"
    if -e $vm->image_path;

# create the virtual machine
chdir $vm->machine_path;
system $vm->qemu_command;

use Sys::Guestfs;
# mount the machine image
my $h = Sys::Guestfs->new;

$h->add_drive_opts( $vm->image_path, format => $vm->image_format );
$h->launch;

$h->mount_options('', '/dev/vda1', '/');

$h->write('/etc/network/interfaces', $vm->network_template);
$h->write('/etc/hostname', $vm->hostname);
$h->write('/etc/hosts', $vm->hosts_template);

use Sys::Virt;
my $address = 'qemu:///system';
my $vmm = Sys::Virt->new(address => $address,);

foreach my $dom ($vmm->list_defined_domains) {
    if ($vm->full_name eq $dom->get_name) { 
        $dom->destroy if $dom->is_active;
        $dom->undefine;
    }
}

my $dom = $vmm->define_domain($vm->domain_xml);
$dom->create;
