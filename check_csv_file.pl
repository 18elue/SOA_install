#!/usr/bin/perl
use strict;
use warnings;

use lib 'perl_modules';
use Storable qw(dclone);
use Data::Dumper;

use SOA::Install::Util qw(
	get_data_from_csv 
	list_to_hash
	list_data_preprocess 
	hash_data_preprocess 
	set_default_configuration
	divide_into_domains
);

my ($hash_data_aref, $domain_unit_aref) = get_data_aref();
each_domain_check($domain_unit_aref);
#uid_gid_check($hash_data_aref);
host_domain_port_check($hash_data_aref, $domain_unit_aref);

sub each_domain_check {
	my ($domains_aref) = @_;
	my $domains_aref_bak = dclone($domains_aref);
	for my $domain (@$domains_aref_bak) {
		my $admin_server = shift @$domain;
		my @managed_server = @$domain;
		
		# instance name should not repeat
		my %instance_name_check;
		for my $server (@managed_server) {
			my $instance_name = $server->{"Instance Name"};
			my $host = $server->{"IP Address"};
			my $component = $server->{"Component"};
			if ($instance_name_check{$instance_name}) {
				print "WARNNING: find duplicated instance name $instance_name in host $host, componet $component\n";
			}
			else {
				$instance_name_check{$instance_name} = 1;
			}
		}
		
		# http port should not repeat for the same host
		
	}
}

sub uid_gid_check {
	my ($hash_data_aref) = @_;
	my $hash_data_aref_bak = dclone($hash_data_aref);
	# UID and GID should not repeat for different user
	my %UID_check;
	my %GID_check;
	for my $server (@$hash_data_aref_bak) {
		my $user = $server->{"App OS Username"};
		my $uid = $server->{"UID"};
		my $group = $server->{"Group name"};
		my $gid = $server->{"GID"};
		my $host = $server->{"IP Address"};
		my $component = $server->{"Component"};
		if (!$uid || !$user) {
			print "WARNING: NO UID or USER in host $host, componet $component\n";
		}elsif ($UID_check{$uid} && $UID_check{$uid} ne $user) {
			print "WARNING: find duplicated UID $uid for both $UID_check{$uid} and $user in host $host, componet $component\n";
		}else {
			$UID_check{$uid} = $user;
		}
		
		if (!$gid || !$group) {
			print "WARNING: NO GID or GROUP in host $host, componet $component\n";
		}
		elsif ($GID_check{$gid} && $GID_check{$gid} ne $group) {
			print "WARNING: find duplicated GID $gid for both $GID_check{$gid} and $group in host $host, componet $component\n";
		}else {
			$GID_check{$gid} = $group
		}
	}	
}

sub host_domain_port_check {
	my ($hash_data_aref, $domains_aref) = @_;
	my $hash_data_aref_bak = dclone($hash_data_aref);
	my $domains_aref_bak = dclone($domains_aref);
	# domain name should not repeat for the same host
	my %domain_name_check;
	for my $domain (@$domains_aref_bak) {
		my $admin_server = $domain->[0];
		my $domain_name = $admin_server->{"Domain name"};
		my $component = $admin_server->{"Component"};
		my @host = map{$_->{"IP Address"}}@$domain;
		@host = do {my %seen; grep {!$seen{$_}++} @host};
		for my $host (@host) {
			if (!$domain_name_check{$host}) {
				$domain_name_check{$host} = {};
				$domain_name_check{$host}->{$domain_name} = 1;
			}elsif ($domain_name_check{$host}->{$domain_name}) {
				print "WARNING: find duplicated domain name for host $host, componet $component\n";
			}else {
				$domain_name_check{$host}->{$domain_name} = 1;
			}
		}
	}
	
	# port should not repeat for the same host
	my %http_port_check;
	my %https_port_check;
	my %admin_port_check;
	for my $server (@$hash_data_aref_bak) {
		my $http_port = $server->{"HTTP Port"};
		my $https_port = $server->{"HTTPS Port"};
		my $admin_port = $server->{"Admin Port"};
		my $host = $server->{"IP Address"};
		my $component = $server->{"Component"};
		# http port check
		if ( !$http_port_check{$host} ) {
			$http_port_check{$host} = {};
			$http_port_check{$host}->{$http_port} = 1;
		}elsif ($http_port_check{$host}->{$http_port}) {
			print "WARNING: find duplicated http port $http_port for host $host, componet $component\n";
		}else {
			$http_port_check{$host}->{$http_port} = 1;
		}
	}
}


sub get_data_aref {
	# read data from csv file, get hash data with first list be the key
	my $list_data_aref = get_data_from_csv('./test.csv');
	$list_data_aref = list_data_preprocess($list_data_aref);
	my @list_data = @$list_data_aref;

	my $hash_data_aref = list_to_hash($list_data_aref);
	$hash_data_aref = hash_data_preprocess($hash_data_aref);
	$hash_data_aref = set_default_configuration($hash_data_aref);
	
	#seperate all hash data into domains,divided by "Instance Type" set to Admin/Managed
	my $group_data_aref = divide_into_domains($hash_data_aref);
	return ($hash_data_aref, $group_data_aref);
}