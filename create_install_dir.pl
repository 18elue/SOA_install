#!/usr/bin/perl
use strict;
use warnings;

use lib 'perl_modules';
#use Cwd; #get pathname of current working directory
use Data::Dumper;

use SOA::Install::Util qw(
	get_data_from_csv 
	list_to_hash
	list_data_preprocess 
	hash_data_preprocess 
	set_default_configuration
	divide_into_domains
);
use SOA::Create::SecureCRT qw(create_secureCRT_config);
use SOA::Create::InputFile qw(create_one_input_file);
use SOA::Create::UtilScript qw(
	create_temp_script_for_root
	create_temp_script_for_user
	create_other_info_script
	create_scp_script
);

use SOA::Constant qw(CSV_FILE_NAME);

# read data from csv file, get hash data with first list be the key
my $list_data_aref = get_data_from_csv(CSV_FILE_NAME);
$list_data_aref = list_data_preprocess($list_data_aref);
my @list_data = @$list_data_aref;

my $hash_data_aref = list_to_hash($list_data_aref);
$hash_data_aref = hash_data_preprocess($hash_data_aref);
my @hash_data = @$hash_data_aref;

$hash_data_aref = set_default_configuration($hash_data_aref);

#seperate all hash data into domains,divided by "Instance Type" set to Admin/Managed
my $group_data_aref = divide_into_domains($hash_data_aref);

#the main procedure of create input properties
my $scp_script_filename = "scp.sh";
open (my $scp_file_handler, ">", $scp_script_filename) or die "cannot create > $scp_script_filename : $!";	
for my $domain_aref (@$group_data_aref) {
	my $weblogic_install_dir = create_one_input_file($domain_aref);
	create_other_info_script($domain_aref, $weblogic_install_dir);
	create_secureCRT_config($domain_aref);
	create_scp_script($scp_file_handler, $domain_aref, $weblogic_install_dir);
	
	#this is temporary used
	create_temp_script_for_root($domain_aref);
	create_temp_script_for_user($domain_aref);
	system "./create_weblogic_install_dir.bash", $weblogic_install_dir;
}
close $scp_file_handler;





