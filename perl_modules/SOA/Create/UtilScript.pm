package SOA::Create::UtilScript;

use strict;
use warnings;

use Data::Dumper;
use SOA::Constant qw(
	ORACLE_HOME
	LOG_DISK_MOUNTED_DIR APP_DISK_MOUNTED_DIR LOG_SOFT_LINK APP_SOFT_LINK
	SRC_WLS_FILE_DIR SRC_WLS_FILE_NAME EXTRACTED_WLS_FILE_NAME INSTALL_FILE_DIR
	SRC_SOA_FILE_DIR SRC_SOA_FILE_NAME
);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	create_temp_script_for_root
	create_temp_script_for_user
	create_other_info_script
	create_scp_script
);

sub create_temp_script_for_root {
	my ($row_aref, $dynamic_property) = @_;
	my $file_name = "root_temp_script.sh";
	open (my $fh, ">", $file_name) or die "cannot create > $file_name : $!";
	printf $fh "rm -rf %s \n", LOG_SOFT_LINK;
	printf $fh "ln -s %s %s \n", LOG_DISK_MOUNTED_DIR, LOG_SOFT_LINK;
	printf $fh "rm -rf %s \n", APP_SOFT_LINK;
	printf $fh "ln -s %s %s \n", APP_DISK_MOUNTED_DIR, APP_SOFT_LINK;	
	printf $fh "chown -R %s:%s %s \n", $row_aref->[0]->{"App OS Username"}, $row_aref->[0]->{"Group name"}, LOG_DISK_MOUNTED_DIR;
	printf $fh "chown -R %s:%s %s \n", $row_aref->[0]->{"App OS Username"}, $row_aref->[0]->{"Group name"}, APP_DISK_MOUNTED_DIR;
	printf $fh "rm -rf %s \n", $dynamic_property->{"BEAHOME"};
	close $fh;
}

sub create_temp_script_for_user {
	my ($row_aref, $dynamic_property, $SOA_flag) = @_;
	my $file_name = "user_temp_script.sh";
	open (my $fh, ">", $file_name) or die "cannot create > $file_name : $!";
	if ($SOA_flag) {
		printf $fh "scp -r %s %s \n", SRC_SOA_FILE_DIR.SRC_SOA_FILE_NAME, ORACLE_HOME;
		printf $fh "tar -xf %s -C %s \n", ORACLE_HOME.SRC_SOA_FILE_NAME, ORACLE_HOME;
		printf $fh "rm -rf %s \n", ORACLE_HOME.SRC_SOA_FILE_NAME;
	} else {
		printf $fh "scp -r %s %s \n", SRC_WLS_FILE_DIR.SRC_WLS_FILE_NAME, ORACLE_HOME;
		printf $fh "tar -xf %s -C %s \n", ORACLE_HOME.SRC_WLS_FILE_NAME, ORACLE_HOME;
		printf $fh "rm -rf %s \n", ORACLE_HOME.SRC_WLS_FILE_NAME;
		printf $fh "ln -s %s %s \n", ORACLE_HOME.EXTRACTED_WLS_FILE_NAME, $dynamic_property->{"BEAHOME"};
	}
#	printf $fh "chmod -R 777 %s \n", LOG_DISK_MOUNTED_DIR;
#	printf $fh "chmod -R 777 %s \n", APP_DISK_MOUNTED_DIR;
	close $fh;
}

# this func is used to create extra shell command like create log dir
sub create_other_info_script {
	my ($row_aref, $weblogic_install_dir, $dynamic_property) = @_;

	# get all hosts
	my @host;
	for my $row(@$row_aref) {
		push @host, $row->{"IP Address"};
	}
	@host = do { my %seen; grep { !$seen{$_}++ } @host };
	
	my %ip_to_file_handler;
	for my $host (@host) {
		my $host_name = $host;
		$host_name =~ s/\./_/g;
		my $file_name = "other_info_".$host_name.".sh";
		open ($ip_to_file_handler{$host}, ">", $file_name) or die "cannot create > $file_name : $!";
	}
	
	# create log dir
	for my $row (@$row_aref) {
		my $host = $row->{"IP Address"};
		my $node_log_dir = sprintf "%s/%s/servers/%s/logs", $dynamic_property->{"DOMAIN_DIR"}, $row->{"Domain name"}, $row->{"Instance Name"};

		printf {$ip_to_file_handler{$host}} "#create log dir\n";
		printf {$ip_to_file_handler{$host}} "#node %s\n", $row->{"Instance Name"};
		printf {$ip_to_file_handler{$host}} "[[ -e %s ]] && rm -rf %s && echo \"%s dir deleted\"\n", $node_log_dir, $node_log_dir, $node_log_dir;
		printf {$ip_to_file_handler{$host}} "mkdir -p %s\n", $row->{"Log File"};
		printf {$ip_to_file_handler{$host}} "ln -s %s %s && echo \"soft link for %s created\"\n\n", $row->{"Log File"}, $node_log_dir, $row->{"Instance Name"};
	}
	
	# copy start script
	for my $host (keys %ip_to_file_handler) {
		printf {$ip_to_file_handler{$host}} "#copy start script\n";
		printf {$ip_to_file_handler{$host}} "cp %s/%s/start_script/$host/* %s/%s/bin && echo \"cp start script finished\" \n", INSTALL_FILE_DIR, $weblogic_install_dir, $dynamic_property->{"DOMAIN_DIR"}, $row_aref->[0]->{"Domain name"};
	}
	
	# close file handler
	map { close $_ } values %ip_to_file_handler; 
}

sub create_scp_script {
	my ($file_handler, $row_aref, $weblogic_install_dir) = @_;
	
	my @uniq_host_row;
	@uniq_host_row = do { my %seen; grep { !$seen{$_->{"IP Address"}}++ } @$row_aref };	
	
	for my $row (@uniq_host_row) {
		printf $file_handler "scp -r %s %s@%s:%s\n", $weblogic_install_dir, $row->{"App OS Username"}, $row->{"IP Address"}, INSTALL_FILE_DIR;
		printf $file_handler "ssh %s@%s 'cd %s%s/domain_create && ./set_domain.sh > script_run_result.log &'\n", $row->{"App OS Username"}, $row->{"IP Address"}, INSTALL_FILE_DIR, $weblogic_install_dir;
	}	
}

1;