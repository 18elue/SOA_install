package SOA::Constant;

use strict;
use warnings;

use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	CSV_FILE_NAME
	ORACLE_HOME BEAHOME DOMAIN_DIR DOMAIN_TEMPLATE JAVA_HOME WEBLOGIC_CLASSPATH
	BEAHOME_SHORTCUT
	LOG_FILE XMS XMX MAXPERMSIZE
	SecureCRT_CONFIG_DIR SecureCRT_TEMPLATE_FILENAME
	LOG_DISK_MOUNTED_DIR APP_DISK_MOUNTED_DIR LOG_SOFT_LINK APP_SOFT_LINK
	SRC_WLS_FILE_DIR SRC_WLS_FILE_NAME INSTALL_FILE_DIR
);

use constant CSV_FILE_NAME => './test.csv';
use constant ORACLE_HOME => '/usr/local/oracle/';
use constant BEAHOME => ORACLE_HOME.'wls103602/';
#use constant BEAHOME_SHORTCUT => ORACLE_HOME.'wls-latest';
use constant BEAHOME_SHORTCUT => ORACLE_HOME.'mw';

use constant {
	SRC_WLS_FILE_DIR => 'Bgaa@113.52.160.29:/usr/local/oracle/',
	SRC_WLS_FILE_NAME => 'wls103602.tar.gz',
	INSTALL_FILE_DIR => '/var/tmp/',
};

use constant {
	DOMAIN_DIR => BEAHOME_SHORTCUT.'/domains',
	DOMAIN_TEMPLATE => BEAHOME_SHORTCUT.'/wlserver_10.3/common/templates/domains/wls.jar',
	JAVA_HOME => BEAHOME_SHORTCUT.'/jdk',
	WEBLOGIC_CLASSPATH => BEAHOME_SHORTCUT.'/wlserver_10.3/server/lib/weblogic.jar',
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
};

use constant {
	SecureCRT_CONFIG_DIR => '/home/6375ly/VanDyke/Config/Sessions/SOA',
	SecureCRT_TEMPLATE_FILENAME => '/home/6375ly/SOA_install_script/SecureCRT_TEMPLATE/connect.ini',
};

1;