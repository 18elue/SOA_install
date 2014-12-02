package SOA::Constant;

use strict;
use warnings;

use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	CSV_FILE_NAME
	ORACLE_HOME RELATIVE_DOMAIN_TEMPLATE RELATIVE_WLST_PATH
	LOG_FILE XMS XMX MAXPERMSIZE DEFAULT_WLS_PASSWORD
	SecureCRT_CONFIG_DIR SecureCRT_TEMPLATE_FILENAME
	LOG_DISK_MOUNTED_DIR APP_DISK_MOUNTED_DIR LOG_SOFT_LINK APP_SOFT_LINK
	SRC_WLS_FILE_DIR SRC_WLS_FILE_NAME EXTRACTED_WLS_FILE_NAME INSTALL_FILE_DIR
	SRC_SOA_FILE_DIR SRC_SOA_FILE_NAME
);

use constant CSV_FILE_NAME => './test.csv';
use constant ORACLE_HOME => '/usr/local/oracle/';

use constant {
	SRC_WLS_FILE_DIR => 'Bgaa@113.52.160.29:/usr/local/oracle/',
	SRC_WLS_FILE_NAME => 'wls103602.tar.gz',
	EXTRACTED_WLS_FILE_NAME => 'wls103602',
	SRC_SOA_FILE_DIR => 'Bgigsoa@113.52.160.40:/usr/local/oracle/',
	SRC_SOA_FILE_NAME => 'mw.tar.gz',
	INSTALL_FILE_DIR => '/var/tmp/',
};

use constant {
	RELATIVE_DOMAIN_TEMPLATE => "/wlserver_10.3/common/templates/domains/wls.jar",
	RELATIVE_WLST_PATH => "/wlserver_10.3/common/bin/wlst.sh",
};

use constant {
	LOG_DISK_MOUNTED_DIR => '/sanfs/mnt/vol02',
	APP_DISK_MOUNTED_DIR => '/sanfs/mnt/vol01',
	LOG_SOFT_LINK        => '/sites',
	APP_SOFT_LINK        => ORACLE_HOME,
};

use constant {
	LOG_FILE => "/sites/%s/site/common/logs/103602_%s",
	XMS => '1024',
	XMX => '1024',
	MAXPERMSIZE =>'512',
	DEFAULT_WLS_PASSWORD => 'Pass1234',
};

use constant {
	SecureCRT_CONFIG_DIR => '/home/6375ly/VanDyke/ConfigVanDyke1/Sessions/SOA',
	SecureCRT_TEMPLATE_FILENAME => '/home/6375ly/SOA_install_script/SecureCRT_TEMPLATE/connect.ini',
};

1;