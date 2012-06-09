#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Sys::Virt;
my $address = 'qemu:///system';

my $vmm = Sys::Virt->new(address => $address,);
