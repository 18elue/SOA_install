package SOA::Install::Util;

use strict;
use warnings;

use Data::Dumper;
use SOA::Constant qw(LOG_FILE XMS XMX MAXPERMSIZE);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	get_data_from_csv 
	list_to_hash
	list_data_preprocess 
	hash_data_preprocess 
	set_default_configuration 
	divide_by_key
	merge_componet
	divide_into_domains
);



sub get_data_from_csv {
	my ($csv_file_name) = @_;
	
	#open csv file
	open(my $csv_file_handler, "<", $csv_file_name) or die "cannot read < $csv_file_name : $!";

	#read csv file
	my @list_data;
	while(my $line = <$csv_file_handler>){
		$/="\r\n";
		chomp $line;
		next if !$line;  # ignore blank line
		my @row = split ',' , $line;
		push @list_data, \@row;
	}
	close $csv_file_handler;
	
	return \@list_data;
}

sub list_data_preprocess {
	my ($list_data_aref) = @_;
	
	#change row from array to hash by using head column as the key
	my $head_list = $list_data_aref->[0];
	map { s/"//g } @$head_list; # for head row, delete colon if there is any
	
	return $list_data_aref;	
}

sub list_to_hash {
	my ($list_data_aref) = @_;
	
	#delete head data
	my $head_list = shift @$list_data_aref;
	
	my @hash_data;
	for my $row (@$list_data_aref) {
		my $obj = {};
		my $index = 0;
		for my $column (@$row) {
			my $key = $head_list->[$index];
			$index += 1;
			$obj->{$key} = $column;
		}
		push @hash_data, $obj;
	}
	
	return \@hash_data;
}

sub hash_data_preprocess {
	my ($hash_data_aref) = @_;
	
	# change component content
	for my $obj (@$hash_data_aref) {
		$obj->{"Component"} =~ s/ /_/g;
		$obj->{"Component"} =~ s/\(/_/g;
		$obj->{"Component"} =~ s/\)/_/g;
	}
	
	#delete columns which does not have domain name
	my @hash_data = grep { $_->{"Domain name"} && $_->{"Instance Type"} } @$hash_data_aref;
	
	#the "Instance Type" should be only Admin or Managed
	for my $obj (@hash_data) {
		if ($obj->{"Instance Type"} =~ /Admin/i) {
			$obj->{"Instance Type"} = 'Admin';
		}
		elsif ($obj->{"Instance Type"} =~ /Manage/i) {
			$obj->{"Instance Type"} = 'Manage';
		}
		else {
			warn "the value of Instance Type need to be either Admin or Manage!";
			exit 1;
		}
	} 
	
	return \@hash_data;
}

sub set_default_configuration {
	my ($hash_data_aref) = @_;

	#set default value if no specific set, like log dir,Xms(G),Xmx(G),XX:MaxPermSize(G)
	for my $obj (@$hash_data_aref) {
		if (!$obj->{"Log File"}) {
			$obj->{"Log File"} = sprintf LOG_FILE, $obj->{"Domain name"}, $obj->{"Instance Name"};
		}
		if (!$obj->{"Xms(G)"}) {
			$obj->{"Xms(G)"} = XMS;
		}
		if (!$obj->{"Xmx(G)"}) {
			$obj->{"Xmx(G)"} = XMX;
		}
		if (!$obj->{"XX:MaxPermSize(G)"}) {
			$obj->{"XX:MaxPermSize(G)"} = MAXPERMSIZE;
		}
	}
	
	return $hash_data_aref;
}

sub divide_by_key {
	my ($hash_data_aref, $divide_key) = @_;
	my @group_data;
	my @current_group = ();
	my $divide_value = $hash_data_aref->[0]->{$divide_key};
	for my $obj (@$hash_data_aref) {
		if ($obj->{$divide_key} eq $divide_value) {
			push @current_group, $obj;
		}
		else {
			my @group_copy = @current_group;
			push @group_data, \@group_copy;
			@current_group = ();
			$divide_value = $obj->{$divide_key};
			push @current_group, $obj;
		}
	}
	push @group_data, \@current_group; # add the last component
	return \@group_data;
}

sub merge_componet {
	my ($component_aref_aref) = @_;
	my @component_aref = @$component_aref_aref;
	my @final_component;
	for my $component (@component_aref) {
		my @admin_instance = grep { $_->{"Instance Type"} =~ /Admin/i } @$component;
		if ( scalar @admin_instance) {
			push @final_component, $component;
		}
		else {    # if component does not have admin instance, add it into before component
			my $before_component = pop @final_component;
			push @$before_component, @$component;
			push @final_component, $before_component;
		}
	}
	return @final_component;
}

sub divide_into_domains {
	my ($hash_data_aref) = @_;
	
	my @group_data;
	my @current_group = ();	
	
	# the first line need to be "Admin"
	my $first_obj = shift @$hash_data_aref;
	if ($first_obj->{"Instance Type"} ne 'Admin') {
		warn "the first line instance type need to be Admin!";
		exit 1;
	}
	else {
		push @current_group, $first_obj;
	}
	
	for my $obj (@$hash_data_aref) {
		if ($obj->{"Instance Type"} eq 'Manage') {
			push @current_group, $obj;
		}
		if ($obj->{"Instance Type"} eq 'Admin') {
			my @group_copy = @current_group;
			push @group_data, \@group_copy;
			@current_group = ();
			push @current_group, $obj;
		}
	}
	push @group_data, \@current_group; # add the last group
	
	# TO DO : validate if all rows are in the same domain 
	
	return \@group_data;
}


1;