use strict;
use warnings;
package PrepVM::App;

use Moose;

has 'hostname' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'machine_type' => (
    is  => 'rw',
    isa => 'Str',
);

has 'machine_path' => (
    is  => 'rw',
    isa => 'Str',
    default => '/media/KVM/machines/',
);

has 'image_type' => (
    is  => 'rw',
    isa => 'Str',
    default => 'ubuntu-server-12.04-precise-x86_64',
    required => 1,
);

has 'image_format' => (
    is  => 'rw',
    isa => 'Str',
    default => 'qcow2',
    required => 1,
);

has 'ip_address' => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has 'netmask'    => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has 'gateway'   => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has 'nameserver' => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has 'hosts_template' => (
    is  => 'rw',
    isa => 'Str',
    lazy    => 1,
    builder => '_build_hosts_template',
);

has 'network_template' => (
    is  => 'rw',
    isa => 'Str',
    lazy    => 1,
    builder => 'build_network_template',
);

has 'puppet_address' => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
    default => '192.168.0.2',
);

has 'puppet_name' => (
    is  => 'rw',
    isa => 'Str',
    required    => 1,
    default => 'puppet',
);

sub _build_hosts_template {
    my $self = shift;
    my $host = $self->hostname;
    my $puppet_address = $self->puppet_address;
    my $puppet_name    = $self->puppet_name;

my $hosts =<<END_TEMPLATE;
127.0.0.1   localhost
127.0.1.1   $host

$puppet_address     $puppet_name

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END_TEMPLATE

    return $hosts;

}

sub _build_network_template {
    my $self = shift;
    my $ip  = $self->ip_address;
    my $netmask = $self->netmask;
    my $gateway = $self->gateway;
    my $nameserver = $self->nameserver;

my $network_template =<<END_TEMPLATE;
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
END_TEMPLATE

    return $network_template;
}


1;
