#!/usr/bin/perl

use strict;
use warnings;

use Sys::Guestfs;

use Config::Any;


use lib './lib';
use PrepVM::App;

#my $config = @ARGV[0];
#my $cfg = Config::Any->load_files({ files => [$config], use_ext => 1 })->[0]->{$config_file};


my $vm = PrepVM::App->new(
    {
        machine_type    => 'auto',
        hostname        => 'titus',
        ip_address      => '192.168.0.18',
        gateway         => '192.168.0.1',
        netmask         => '255.255.0.0',
        nameserver      => '192.168.0.2',
    }
);

print $vm->hosts_template;
print $vm->network_template;

__END__
my $hostname = 'titus';

my $path = '/media/KVM/machines/';

my $image = "auto-$hostname-ubuntu-server-12.04-precise-x86_64.qcow2";
my $format = 'qcow2';

my $h = Sys::Guestfs->new;

$h->add_drive_opts( $path . $image, format => $format );
$h->launch;

my $config = get_config ('192.168.0.18', 
                            '255.255.0.0', 
                            '192.168.0.1', 
                            '192.168.0.2',
);

$h->mount_options('', '/dev/vda1', '/');

$h->write('/etc/network/interfaces', $config);
$h->write('/etc/hostname', $hostname);
$h->write('/etc/hosts', get_hosts($hostname, '192.168.0.2'));

sub get_config {
    my ($ip, $netmask, $gateway, $nameserver) = @_;

my $config =<<END_FILE;
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
    address $ip
    netmask $netmask
    gateway $gateway
    dns-nameservers $nameserver
END_FILE
    return $config;
}

sub get_hosts {
    my $host = shift;
    my $puppet = shift;

my $config=<<END_FILE;
127.0.0.1   localhost
127.0.1.1   $host

$puppet     puppet

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END_FILE
    
    return $config;
}
