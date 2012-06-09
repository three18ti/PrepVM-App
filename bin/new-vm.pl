#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Getopt::Long;

my ($overwrite, $help);

GetOptions(
    "force"     => \$overwrite,
    "help"      => \$help,
);

print_help() if $help;

use lib './lib';
use PrepVM::App;

die "Please indicate a valid Machine Config\n"
    . "use --help for help"
    unless @ARGV;

use Sys::Virt;
my $address = 'qemu:///system';
my $vmm = Sys::Virt->new(address => $address,);

# load the VM config
use Config::Any;
my $config = $ARGV[0];
my $cfg = Config::Any->load_files({ files => [$config], use_ext => 1 })->[0]->{$config};
my $vm = PrepVM::App->new( $cfg );

# check for an existing VM
if ($overwrite) {
    foreach my $dom ($vmm->list_defined_domains) {
        $dom->undefine if $vm->full_name eq $dom->get_name;
    }
    foreach my $dom ($vmm->list_domains) {
        do {
            $dom->destroy if $dom->is_active;
            $dom->undefine;
        } if $vm->full_name eq $dom->get_name;
    }
    unlink $vm->image_path;
}

die "Image: " . $vm->image_path 
    . "\nAlready Exists, please remove before continuing\n"
    . "\nuse -f|--force to overwrite, or --help for help\n"
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

my $dom = $vmm->define_domain($vm->domain_xml);
$dom->create;

sub print_help {
    die<<END_HELP;
usage new-vm.pl [-f] [config-file.yml]

    -f|--force      purge any existing machines under the same name
    -h|--help       print this message and exit
END_HELP
}
