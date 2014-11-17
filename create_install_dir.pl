#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use lib 'perl_modules';
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
	cp_domain
	run_other_info
);

use SOA::Constant qw(ORACLE_HOME RELATIVE_DOMAIN_TEMPLATE RELATIVE_WLST_PATH CSV_FILE_NAME);

# dealing with command line options
my $SOA_flag = 0;
=x
GetOptions(
	"SOA" => \$SOA_flag,  # to install SOA, need to set SOA flag
	) 
or die ("Error in command line arguments\n");
=cut 

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

	my ($beahome, $create_machine_flag);
	my $domain_type = 'WLS';
	my $admin_server = $domain_aref->[0];
	my $managed_server = $domain_aref->[1];
	
	if ($admin_server->{'Software'} =~ /SOA/i) {
		$beahome = ORACLE_HOME.'mw';
		$create_machine_flag = 0;
	} else {
		$beahome = ORACLE_HOME.'wls-latest';
		$create_machine_flag = 1;
	}
	
	if ($managed_server->{'Instance Type'} =~ /soa/i) {
		$domain_type = 'SOA';
	}elsif ($managed_server->{'Instance Type'} =~ /osb/i ) {
		$domain_type = 'OSB';
	}
	
	my $dynamic_property = {
		DOMAIN_DIR => $beahome."/domains",
		JAVA_HOME  => $beahome."/jdk",
		BEAHOME    => $beahome,
		DOMAIN_TEMPLATE => $beahome.RELATIVE_DOMAIN_TEMPLATE,
		WLST_PATH => $beahome.RELATIVE_WLST_PATH,
		create_machine_flag => $create_machine_flag,
		DOMAIN_TYPE => $domain_type,
	};	
	
	my $weblogic_install_dir = create_one_input_file($domain_aref, $dynamic_property);
	create_other_info_script($domain_aref, $weblogic_install_dir, $dynamic_property);
	cp_domain($domain_aref, $weblogic_install_dir, $dynamic_property);
	run_other_info($domain_aref, $weblogic_install_dir, $dynamic_property);
	create_secureCRT_config($domain_aref);
	create_scp_script($scp_file_handler, $domain_aref, $weblogic_install_dir, $dynamic_property);
	
	#this is temporary used
	create_temp_script_for_root($domain_aref, $dynamic_property);
	create_temp_script_for_user($domain_aref, $dynamic_property, $SOA_flag);
	system "./create_weblogic_install_dir.bash", $weblogic_install_dir;
}
close $scp_file_handler;





