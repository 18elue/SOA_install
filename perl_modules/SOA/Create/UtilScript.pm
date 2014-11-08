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
	cp_domain
	run_other_info
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
	
	my @row = @$row_aref;
	my $admin_server_row = shift @row;
	
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
		printf {$ip_to_file_handler{$host}} "cp %s/%s/start_script/$host/* %s/%s/bin && echo \"cp start script finished\" \n\n", INSTALL_FILE_DIR, $weblogic_install_dir, $dynamic_property->{"DOMAIN_DIR"}, $row_aref->[0]->{"Domain name"};
	}
	
	# start admin server
	my $admin_ip = $admin_server_row->{"IP Address"};
	printf {$ip_to_file_handler{$admin_ip}} "#start admin server\n";
	printf {$ip_to_file_handler{$admin_ip}} "%s/%s/bin/start\n", $dynamic_property->{"DOMAIN_DIR"}, $row_aref->[0]->{"Domain name"};
	printf {$ip_to_file_handler{$admin_ip}} "sleep 30\n\n";
	printf {$ip_to_file_handler{$admin_ip}} "#start managed server\n";
	
	# start managed server	
	for my $row (@row) {	
		my $host = $row->{"IP Address"};
		printf {$ip_to_file_handler{$host}} "%s/%s/bin/start_%s;", $dynamic_property->{"DOMAIN_DIR"},$row->{"Domain name"},$row->{"Instance Name"};
	}	
	
	# close file handler
	map { close $_ } values %ip_to_file_handler; 
}

# this func is used to copy domain dir to other managed servers
sub cp_domain {
	my ($row_aref, $weblogic_install_dir, $dynamic_property) = @_;
	
	# create expect script to copy domain and execute other info script
	my $file_name = "cp_domain.expect";
	open (my $fh, ">", $file_name) or die "cannot create > $file_name : $!";
	printf $fh "#!/usr/local/bin/expect \n";
	
	# seperate admin server and managed server
	my @row = @$row_aref;
	my $admin_server_row = shift @row;
	my @managed_server_row = @row;
	my $host_check = {};
	for my $managed_server_row (@managed_server_row) {
		my $ip = $managed_server_row->{"IP Address"};
		my $other_info_ip = $ip;
		$other_info_ip =~ s/\./_/g;
		my $other_info_filename = "other_info_".$other_info_ip.".sh";
		if ( $ip ne $admin_server_row->{"IP Address"} && ! exists $host_check->{$ip}) {
			$host_check->{$ip} = 1;
			my $string1 = << "EXPECT1";
spawn scp -r %s/%s %s@%s:%s
expect "(yes/no)?" {
send "yes\r"
}
EXPECT1
			my $string2 = << "EXPECT2";
expect eof
expect "Password:" {
send "%s\r"
}
expect eof
EXPECT2
			printf $fh $string1, $dynamic_property->{"DOMAIN_DIR"},$managed_server_row->{"Domain name"},$managed_server_row->{"App OS Username"},$managed_server_row->{"IP Address"},$dynamic_property->{"DOMAIN_DIR"};
			printf $fh $string2, $managed_server_row->{"App OS Password"};
		}
	}
	close $fh;
}


sub run_other_info {
	my ($row_aref, $weblogic_install_dir, $dynamic_property) = @_;
	
	# create expect script to copy domain and execute other info script
	my $file_name = "run_other_info.expect";
	open (my $fh, ">", $file_name) or die "cannot create > $file_name : $!";
	printf $fh "#!/usr/local/bin/expect \n";
	
	# seperate admin server and managed server
	my @row = @$row_aref;
	my $admin_server_row = shift @row;
	my @managed_server_row = @row;
	my $host_check = {};
	for my $managed_server_row (@managed_server_row) {
		my $ip = $managed_server_row->{"IP Address"};
		my $other_info_ip = $ip;
		$other_info_ip =~ s/\./_/g;
		my $other_info_filename = "other_info_".$other_info_ip.".sh";
		if ( $ip ne $admin_server_row->{"IP Address"} && ! exists $host_check->{$ip}) {
			$host_check->{$ip} = 1;
			my $string3 = << "EXPECT3";
spawn ssh %s@%s '%s/%s/domain_create/%s'
expect "Password:" {
send "%s\r"
}
expect eof
EXPECT3
			printf $fh $string3, $managed_server_row->{"App OS Username"}, $managed_server_row->{"IP Address"},INSTALL_FILE_DIR,$weblogic_install_dir,$other_info_filename,$managed_server_row->{"App OS Password"};
		}
	}
	close $fh;
}

sub create_scp_script {
	my ($file_handler, $row_aref, $weblogic_install_dir) = @_;
	
	my @row = @$row_aref;
	my $admin_server_row = shift @row;
	my @uniq_host_row;
	@uniq_host_row = do { my %seen; grep { !$seen{$_->{"IP Address"}}++ } @$row_aref };	
	
	for my $row (@uniq_host_row) {
		printf $file_handler "scp -r %s %s@%s:%s\n", $weblogic_install_dir, $row->{"App OS Username"}, $row->{"IP Address"}, INSTALL_FILE_DIR;
	}
	printf $file_handler "ssh %s@%s 'cd %s%s/domain_create && ./set_domain.sh > script_run_result.log &'\n\n", $admin_server_row->{"App OS Username"}, $admin_server_row->{"IP Address"}, INSTALL_FILE_DIR, $weblogic_install_dir;
}

1;