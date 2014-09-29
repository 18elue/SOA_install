package SOA::Create::InputFile;

use strict;
use warnings;

use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(create_one_input_file);

sub create_one_input_file {
	my ($row_aref, $dynamic_property) = @_;
	
	# seperate admin server and managed server
	my @row = @$row_aref;
	my $admin_server_row = shift @row;
	my @managed_server_row = @row;

	# check if admin server and managed server is all there
	if(!$admin_server_row || ! scalar @managed_server_row) {
		warn "no admin server or managed server";
		exit 1;
	}
	
	# get all machines
	my @machine;
	for my $row(@$row_aref) {
		push @machine, $row->{"Zone Name"};
	}
	@machine = do { my %seen; grep { !$seen{$_}++ } @machine };

	# create input.properties file
	my $input_file_name = "input.properties";
	open (my $input_file_handler, ">", $input_file_name) or die "cannot create > $input_file_name : $!";

	printf $input_file_handler "WEBLOGIC_USER=weblogic\n";
	printf $input_file_handler "WEBLOGIC_PWD=%s\n", $admin_server_row->{"Weblogic Password"};
	printf $input_file_handler "DOMAIN_NAME=%s\n\n", $admin_server_row->{"Domain name"};

	printf $input_file_handler "BEAHOME=%s\n", $dynamic_property->{"BEAHOME"};
	printf $input_file_handler "DOMAIN_DIR=%s\n", $dynamic_property->{"DOMAIN_DIR"};
	printf $input_file_handler "DOMAIN_TEMPLATE=%s\n", $dynamic_property->{"DOMAIN_TEMPLATE"};
	printf $input_file_handler "WLST_PATH=%s\n", $dynamic_property->{"WLST_PATH"};
	
	printf $input_file_handler "JAVA_HOME=%s\n", $dynamic_property->{"JAVA_HOME"};;
	printf $input_file_handler "Xms=%s\n", $admin_server_row->{"Xms(G)"};
	printf $input_file_handler "Xmx=%s\n", $admin_server_row->{"Xmx(G)"};
	printf $input_file_handler "MaxPermSize=%s\n\n", $admin_server_row->{"XX:MaxPermSize(G)"};
			
	printf $input_file_handler "ADMIN_SERVER_NAME=%s\n", $admin_server_row->{"Instance Name"};
	printf $input_file_handler "ADMIN_SERVER_PORT=%s\n", $admin_server_row->{"HTTP Port"};
	printf $input_file_handler "ADMIN_SERVER_ADDRESS=%s\n\n", $admin_server_row->{"IP Address"};
	printf $input_file_handler "ADMIN_LOG_DIR=%s\n\n", $admin_server_row->{"Log File"};

	printf $input_file_handler "MACHINE=%s\n\n", join(',', @machine);

	## print managed server info
	my @managed_server_key;
	for my $num (1..@managed_server_row) {
		push @managed_server_key, "MANAGED_SERVER_$num";
	}
	printf $input_file_handler "MANAGED_SERVER=%s\n", join(',', @managed_server_key);
	my $index=1;
	for my $managed_server (@managed_server_row) {
		printf $input_file_handler "MANAGED_SERVER_%d_NUM=%s\n", $index, $index;
		printf $input_file_handler "MANAGED_SERVER_%d_NAME=%s\n", $index, $managed_server->{"Instance Name"};
		printf $input_file_handler "MANAGED_SERVER_%d_PORT=%s\n", $index, $managed_server->{"HTTP Port"};
		printf $input_file_handler "MANAGED_SERVER_%d_HTTPS_PORT=%s\n", $index, $managed_server->{"HTTPS Port"};
		printf $input_file_handler "MANAGED_SERVER_%d_ADDRESS=%s\n", $index, $managed_server->{"IP Address"};
		printf $input_file_handler "MANAGED_SERVER_%d_MACHINE=%s\n", $index, $managed_server->{"Zone Name"};
		printf $input_file_handler "MANAGED_SERVER_%d_CLUSTER=%s\n", $index, $managed_server->{"Cluster name"};
		printf $input_file_handler "MANAGED_SERVER_%d_LOG_DIR=%s\n\n", $index, $managed_server->{"Log File"};
		$index += 1;
	}

	printf $input_file_handler "ALL_NODES=(%s %s)\n", $admin_server_row->{"Instance Name"}, join(' ', map {$_->{"Instance Name"}} @managed_server_row);
	printf $input_file_handler "MANAGED_SERVER_NAMES=(%s)\n", join(' ', map {$_->{"Instance Name"}} @managed_server_row);
	printf $input_file_handler "SERVUSER=%s\n", $admin_server_row->{"App OS Username"};
	printf $input_file_handler "T3_URL=t3://%s:%s\n", $admin_server_row->{"IP Address"}, $admin_server_row->{"HTTP Port"};

	close $input_file_handler;
	
	my $dir = sprintf "%s_domain_%s_create", $admin_server_row->{"Component"}, $admin_server_row->{"Domain name"};
	return $dir;
}

1;