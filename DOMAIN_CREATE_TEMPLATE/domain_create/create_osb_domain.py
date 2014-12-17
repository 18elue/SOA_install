#************************************************************************
# File: create_wls_domain.py
#
# Description:
# This WLST script generates a Weblogic Server 10.3 domain, it reads
# in the property file wls_input.properties as input.
#
# Author: yelu
# Version:0.1
#************************************************************************

import shutil

def init():
    loadProperties('./wls_input.properties')
    loadProperties('./osb_soa_input.properties')
    readTemplate(BEAHOME + '/wlserver_10.3/common/templates/domains/wls.jar')
    addTemplate(BEAHOME + '/Oracle_OSB1/common/templates/applications/wlsb_base.jar') 
    addTemplate(BEAHOME + '/Oracle_OSB1/common/templates/applications/wlsb.jar')
    addTemplate(BEAHOME + '/Oracle_OSB1/common/templates/applications/wlsb_owsm.jar')
    addTemplate(BEAHOME + '/oracle_common/common/templates/applications/oracle.em_11_1_1_0_0_template.jar')
    addTemplate(BEAHOME + '/oracle_common/common/templates/applications/oracle.jrf.ws.async_template_11.1.1.jar')
    print 'add OSB template finished'

def set_domain_option():
    print 'Setting the default admin username and password...'
    cd('/Security/base_domain/User/weblogic')
    cmo.setName(WEBLOGIC_USER)
    cmo.setPassword(WEBLOGIC_PWD)
    print 'Setting domain creation options...'
    startmode = 'prod'
    setOption('CreateStartMenu', 'false')
    setOption('DomainName', DOMAIN_NAME)
    setOption('AppDir', DOMAIN_DIR+'/applications/'+DOMAIN_NAME)
    setOption('JavaHome', JAVA_HOME)
    setOption('OverwriteDomain', 'true')
    setOption('ServerStartMode', startmode)

def set_server(names):
    print 'Setting admin server...'
    cd('/Server/AdminServer')
    cmo.name = ADMIN_SERVER_NAME
    cmo.listenPort = int(ADMIN_SERVER_PORT)
    cmo.listenAddress = ADMIN_SERVER_ADDRESS 
    cd('/')
    cmo.adminServerName = ADMIN_SERVER_NAME
    cluster_status = {}

    first_ms_flag = 0
    for ms in  MANAGED_SERVER.split(','):
        ms_name = names[ms+'_NAME'] 
        ms_port = names[ms+'_PORT']
        ms_address = names[ms+'_ADDRESS']
        ms_cluster = names[ms+'_CLUSTER']
        if first_ms_flag == 0:
            first_ms_flag = 1
            cd('/Server/osb_server1')
            cmo.name = ms_name
            cmo.listenPort = int(ms_port)
            cmo.listenAddress = ms_address
            cd('/')
        else:
            managed_server = create(ms_name, 'Server')
            managed_server.listenPort = int(ms_port)
            managed_server.listenAddress = ms_address
        if ms_cluster:
            if ms_cluster not in cluster_status:
                print 'Createing cluster: ' + ms_cluster
                cluster_status[ms_cluster] = create(ms_cluster, 'Cluster')
                cluster_status[ms_cluster].multicastPort = int('7777')
                cluster_status[ms_cluster].multicastAddress = '239.192.0.1'
                cluster_status[ms_cluster].weblogicPluginEnabled = 1
            print 'Assigning managed servers: (%s) to cluster: %s' % (ms_name, ms_cluster)
            assign('Server', ms_name, 'Cluster', ms_cluster)
            one_address = '%s:%s' % (ms_address, ms_port)
            if cluster_status[ms_cluster].clusterAddress:
                cluster_status[ms_cluster].clusterAddress = cluster_status[ms_cluster].clusterAddress + ',' + one_address
            else:
                cluster_status[ms_cluster].clusterAddress = one_address
            print ''
    return cluster_status

def set_JDBC():
    cd('/JDBCSystemResource/wlsbjmsrpDataSource/JdbcResource/wlsbjmsrpDataSource/JDBCDriverParams/NO_NAME_0')
    set('DriverName','oracle.jdbc.OracleDriver')
    set('URL','jdbc:oracle:thin:@%s:1521/%s' % (DB_HOST, DB_SERVICE_NAME))
    set('PasswordEncrypted', DB_PASSWORD)
    cd('Properties/NO_NAME_0/Property/user')
    set('Value','%s_SOAINFRA' % DB_PREFIX)

    cd('/JDBCSystemResource/mds-owsm/JdbcResource/mds-owsm/JDBCDriverParams/NO_NAME_0')
    set('DriverName','oracle.jdbc.OracleDriver')
    set('URL','jdbc:oracle:thin:@%s:1521/%s' % (DB_HOST, DB_SERVICE_NAME))
    set('PasswordEncrypted', DB_PASSWORD)
    cd('Properties/NO_NAME_0/Property/user')
    set('Value','%s_MDS' % DB_PREFIX)
    print 'set JDBC finished'

def copyfile(src, dest):
    if os.path.isfile(src):
        destpath = os.path.split(dest)[0]

        if not os.path.exists(destpath):
            os.makedirs(destpath)

        shutil.copy2(src, dest)
    else:
        print 'Error: source file does not exist: ' + src

def create_boot_properties(names):
    try:
        print 'Server start mode set for production: creating boot.properties file...'
        srcfile = '%s/%s/servers/%s/security/boot.properties' % (DOMAIN_DIR, DOMAIN_NAME, ADMIN_SERVER_NAME)
        srcpath = os.path.split(srcfile)[0]

        if not os.path.exists(srcpath):
            os.makedirs(srcpath)

        bootfile = open(srcfile, 'w')
        bootfile.write('username=%s\n' % WEBLOGIC_USER)
        bootfile.write('password=%s\n' % WEBLOGIC_PWD)
        bootfile.close()
    except:
        raise 'Error creating boot.properties file.'

    print 'Creating boot.properties files for the managed servers...'
    for ms in  MANAGED_SERVER.split(','):
        ms_name = names[ms+'_NAME'] 
        destfile = '%s/%s/servers/%s/security/boot.properties' % (DOMAIN_DIR, DOMAIN_NAME, ms_name)
        print 'Copying: boot.properties --> ' + destfile
        copyfile(srcfile, destfile)

def start_edit(): 
    print 'Starting admin server...'
    connect_url = 't3://%s:%s' % (ADMIN_SERVER_ADDRESS, ADMIN_SERVER_PORT)
    startServer(ADMIN_SERVER_NAME, DOMAIN_NAME, connect_url, WEBLOGIC_USER, WEBLOGIC_PWD, DOMAIN_DIR+'/'+DOMAIN_NAME, jvmArgs=' -XX:MaxPermSize=256m')
    connect(WEBLOGIC_USER,WEBLOGIC_PWD,connect_url)
    edit()
    startEdit()

def finish_edit():
    save()
    activate()
    print 'Stopping admin server...'
    shutdown(force='true', block='true')

def domain_configuration(cluster_dict):
    for cluster in cluster_dict.keys():
        cd('/Clusters/%s' % cluster)
        print 'Setting Cluster %s communication to UNICAST' % cluster
        set('ClusterMessagingMode','unicast')
    
    cd('/')
    print 'setting Configuration Audit Type to log\n'
    set('ConfigurationAuditType','log')

    print 'setting LockoutThreshold to 6\n'
    cd('/SecurityConfiguration/%s/Realms/myrealm/UserLockoutManager/UserLockoutManager' % DOMAIN_NAME)
    set('LockoutThreshold','6')

    print 'setting LockoutResetDuration to 30\n'
    set('LockoutResetDuration','30')

    cd('/Log/%s' % DOMAIN_NAME)
    print 'setting domain log file rotation type to none\n'
    set('RotationType','None')

    cd('/EmbeddedLDAP/%s' % DOMAIN_NAME)
    print 'setting EmbeddedLDAP Credential\n'
    set('Credential',WEBLOGIC_PWD)

def common_log_setting(log_name):
    pass
    #set('RotationType','byTime')
    #set('RotateLogOnStartup','false')
    #set('RotationTime','00:00')
    #set('FileTimeSpan','24')
    #set('FileCount','60')
    #set('FileName','logs/%s' % log_name)
    #set('NumberOfFilesLimited','true')

def managed_server_setting(ms_name,ms_address):
    print 'setting %s instance parameters:\n' % ms_name
    cd('/Servers/%s' % ms_name)
    print 'setting InterfaceAddress\n'
    set('InterfaceAddress',ms_address)
    print 'setting MSIFileReplicationEnabled to true\n' 
    set('MSIFileReplicationEnabled','true')
    print 'setting WeblogicPluginEnabled to true\n\n\n'
    set('WeblogicPluginEnabled','true')


def server_configuration(names):
    print 'configure admin server log...'
    cd('/Servers/%s/Log/%s' % (ADMIN_SERVER_NAME,ADMIN_SERVER_NAME))
    common_log_setting(ADMIN_SERVER_NAME+'.log')
    cd('/Servers/%s/WebServer/%s/WebServerLog/%s' % (ADMIN_SERVER_NAME,ADMIN_SERVER_NAME,ADMIN_SERVER_NAME))
    common_log_setting('access.log')
   
    if ADMIN_SERVER_HTTPS_PORT:
        print 'configure admin server https port...'
        cd('/Servers/%s/SSL/%s' % (ADMIN_SERVER_NAME,ADMIN_SERVER_NAME))
        cmo.setEnabled(true)
        cmo.setListenPort(int(ADMIN_SERVER_HTTPS_PORT))

    for ms in  MANAGED_SERVER.split(','):
        ms_name = names[ms+'_NAME'] 
        ms_address = names[ms+'_ADDRESS']
        ms_https_port = names[ms+'_HTTPS_PORT']
        print 'configure managed server %s log...' % ms_name
        managed_server_setting(ms_name,ms_address)
        cd('/Servers/%s/Log/%s' % (ms_name,ms_name))
        common_log_setting(ms_name+'.log')
        cd('/Servers/%s/WebServer/%s/WebServerLog/%s' % (ms_name,ms_name,ms_name))
        common_log_setting('access.log')
       
        if ms_https_port:
            print 'configure managed server %s https port...' % ms_name
            cd('/Servers/%s/SSL/%s' % (ms_name,ms_name))
            cmo.setEnabled(true)
            cmo.setListenPort(int(ms_https_port))


def set_passwd_validator():
    cd('/')
    print 'Seeing if Password Validation Provider already exists'
    realm = cmo.getSecurityConfiguration().getDefaultRealm()
    pwdvalidator = realm.lookupPasswordValidator('SystemPasswordValidator')
    if pwdvalidator:
        print 'Password Validator provider is already created'
    else:
        print 'Creating SystemPasswordValidator '
        syspwdValidator = realm.createPasswordValidator('SystemPasswordValidator','com.bea.security.providers.authentication.passwordvalidator.SystemPasswordValidator') 
        print "---  Creation of system Password Validator succeeded!\n"
    print 'Configure SystemPasswordValidator'
    realm = cmo.getSecurityConfiguration().getDefaultRealm()
    pwdvalidator.setMinPasswordLength(8)
    pwdvalidator.setMaxConsecutiveCharacters(3)
    pwdvalidator.setMaxInstancesOfAnyCharacter(4)
    pwdvalidator.setMinAlphabeticCharacters(1)
    pwdvalidator.setMinNumericCharacters(1)
    pwdvalidator.setMinLowercaseCharacters(1)
    pwdvalidator.setMinUppercaseCharacters(1)
    pwdvalidator.setMinNonAlphanumericCharacters(1)
    pwdvalidator.setRejectEqualOrContainUsername(true)
    pwdvalidator.setRejectEqualOrContainReverseUsername(true)


try:
    init()
    set_domain_option()
    symbol_table = locals()
    cluster_dict = set_server(symbol_table)
    set_JDBC()
    writeDomain('%s/%s' % (DOMAIN_DIR,DOMAIN_NAME))
    closeTemplate()     
    create_boot_properties(symbol_table)
    print '\n\n\n*******Start config domain***********\n\n\n'
    start_edit()
    domain_configuration(cluster_dict)
    server_configuration(symbol_table) 
    #set_passwd_validator()
    finish_edit()
except:
    print 'in except'
    dumpStack()
