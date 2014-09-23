package SOA::Create::SecureCRT;

use strict;
use warnings;

use File::Path qw(make_path);
use Data::Dumper;
use SOA::Constant qw(SecureCRT_CONFIG_DIR SecureCRT_TEMPLATE_FILENAME);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(create_secureCRT_config);

sub create_secureCRT_config {
	my ($row_aref) = @_;

	# get all rows with uniq host
	my @host_uniq_row;
	
	@host_uniq_row = do { my %seen; grep { !$seen{$_->{"IP Address"}}++ } @$row_aref};
	
	# read in template file
	my $template_filename = SecureCRT_TEMPLATE_FILENAME;
	open (my $template_fh, "<", $template_filename) or die "cannot read file $template_filename : $!";
	my $template_file_content;
	while (<$template_fh>) {
		$template_file_content .= $_;
	}
	close $template_fh;

	# create config file for each host
	for my $row (@host_uniq_row) {
		my $file_dir = sprintf SecureCRT_CONFIG_DIR."/%s/%s", $row->{"Application"}, $row->{"Env"};
		make_path($file_dir); # create file dir
		
		my $component = $row->{"Component"};
	
		my $file_name = sprintf "$file_dir/%s_%s_%s.ini", $component, $row->{"IP Address"}, $row->{"App OS Username"};
		
		open (my $config_fh, ">", $file_name) or die "cannot create file $file_name : $!";
		my $file_content = $template_file_content;
		$file_content =~ s/\${HOST_NAME}/$row->{"IP Address"}/g;
		$file_content =~ s/\${USER_NAME}/$row->{"App OS Username"}/g;		
		print $config_fh $file_content;
	}
}

1;