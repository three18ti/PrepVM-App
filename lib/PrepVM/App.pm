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

has 'full_name' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $name;
        $name .= $_[0]->machine_type . '-' if $_[0]->machine_type;
        $name .= $_[0]->hostname . '-' . $_[0]->image_type;
    }
);

has 'file_name' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $name = $_[0]->full_name . '.' . $_[0]->image_format;
    }
);

has 'image_path' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $path = $_[0]->machine_path . $_[0]->file_name;
    }
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

has 'base_image' => (
    is  => 'rw',
    isa => 'Str',
    required    => 1,
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
    builder => '_build_network_template',
);

has 'domain_xml' => (
    is  => 'rw',
    isa => 'Str',
    lazy    => 1,
    builder => '_build_domain_xml',
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

has 'qemu_command' => (
    is  => 'rw',
    isa => 'Str',
    lazy    => 1,
    default => sub {
        my $command = 'qemu-img create'
            . ' -b ' . $_[0]->base_image
            . ' -f ' . $_[0]->image_format
            . ' ./'  . $_[0]->file_name
    }
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

sub _build_domain_xml {
    my $self = shift;
    my $name = $self->full_name;
    my $image_path = $self->image_path;

    $name = substr $name, 0, 50, if length $name > 50;

    my $config =<<END_CONFIG;
<domain type='kvm'>
    <name>$name</name>
    <memory>1048576</memory>
    <currentMemory>1048576</currentMemory>
    <vcpu>1</vcpu>
    <os>
        <type arch='x86_64' machine='pc-1.0'>hvm</type>
        <boot dev='hd'/>
    </os>
    <features>
        <acpi/>
        <apic/>
        <pae/>
    </features>
    <clock offset='utc'/>
    <on_poweroff>destroy</on_poweroff>
    <on_reboot>restart</on_reboot>
    <on_crash>restart</on_crash>
    <devices>
        <emulator>/usr/bin/kvm</emulator>
        <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2'/>
            <source file='$image_path'/>
            <target dev='hda' bus='ide'/>
            <alias name='ide0-0-0'/>
            <address type='drive' controller='0' bus='0' unit='0'/>
        </disk>
        <controller type='ide' index='0'>
            <alias name='ide0'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
        </controller>
        <interface type='bridge'>
            <source bridge='br0'/>
            <target dev='vnet1'/>
            <alias name='net0'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
        </interface>
        <serial type='pty'>
            <source path='/dev/pts/3'/>
            <target port='0'/>
            <alias name='serial0'/>
        </serial>
        <console type='pty' tty='/dev/pts/3'>
            <source path='/dev/pts/3'/>
            <target type='serial' port='0'/>
            <alias name='serial0'/>
        </console>
        <input type='mouse' bus='ps2'/>
        <graphics type='vnc' port='5901' autoport='yes'/>
        <video>
            <model type='cirrus' vram='9216' heads='1'/>
            <alias name='video0'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
        </video>
        <memballoon model='virtio'>
            <alias name='balloon0'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
        </memballoon>
    </devices>
    <seclabel type='dynamic' model='apparmor' relabel='yes'>
    </seclabel>
</domain>
END_CONFIG

    return $config;
}

1;
