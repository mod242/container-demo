'''
Created on Oct 23, 2017

@author: Jesse Rodriguez 'rodrigje@us.ibm.com'
'''
import requests
import base64
import json
from http import cookies
import sys
import logging
import logging.config
import os
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class Navigator:
    
    ICM_CONFIG_PLUGIN_ID = 'ICMContainerConfigPlugin'
    ICM_CONFIG_PLUGIN_FEATURE = 'ICMContainerConfig'


    nexusLogon = 'jaxrs/logon'
    nexusLogonSlash = '/jaxrs/getDesktop'

    security_token = ''
    
    cook = cookies.SimpleCookie()
    cook.clear()
    header = {}
    
    # p8 additional properties. 
    global searchMagazineDefCols
    searchMagazineDefCols = ['ActiveMarkings','{CLASS}','ClassificationStatus','ContentRetentionDate','ContentSize','CoordinatedTasks','Creator','CurrentState','DateCheckedIn','DateContentLastAccessed','DateCreated','DateLastModified','CmHoldRelationships','Id','IndexationId','CmIndexingFailureCode','IsCurrentVersion','IsFrozenVersion','IsInExceptionState','CmIsMarkedForDeletion','IsReserved','IsVersioningEnabled','LastModifier','MajorVersionNumber','MimeType','MinorVersionNumber','ReservationType','CmThumbnails','VersionStatus']
    
    global searchDefCols
    searchDefCols = ['ActiveMarkings','{CLASS}','ClassificationStatus','ContentRetentionDate','ContentSize','CoordinatedTasks','Creator','CurrentState','DateCheckedIn','DateContentLastAccessed','DateCreated','DateLastModified','CmHoldRelationships','Id','IndexationId','CmIndexingFailureCode','IsCurrentVersion','IsFrozenVersion','IsInExceptionState','CmIsMarkedForDeletion','IsReserved','IsVersioningEnabled','LastModifier','MajorVersionNumber','MimeType','MinorVersionNumber','{NAME}','ReservationType','VersionStatus']
    
    dirpath = os.path.dirname(__file__)
    logpath = dirpath[:-3]+'logs/logging.conf'
    logging.config.fileConfig(logpath)
    
    global logger
    logger = logging.getLogger('navigator')
    
    
    def getAuthHeader(self, adminUser='', adminPass=''):
#        logger.info('getAuthHeader()')
        logger.info('Going to encrypt username and password for: ' + adminUser)
#        logger.info('adminPass: ' + adminPass)
        authStr = adminUser + ':' + adminPass
        authEncodeStr = base64.b64encode(authStr.encode('ascii'))
        authHeader = 'Basic ' + str(authEncodeStr)
#        logger.info('Basic ' + str(authEncodeStr) )
        authHeaders = {'Content-Type':'application/x-www-form-urlencoded', 'Authorization': authHeader.strip() }    
        return authHeaders 


    def testLogin(self, url='', authHeaders='', adminUser='', adminPass=''):
        logger.info('testLogin()' + url + self.nexusLogon)
        desktopUrl = url + self.nexusLogon
        logger.info( 'desktopUrl: ' + desktopUrl )
        params = {}
        params['desktop'] = 'admin'
        for x  in params:
          logger.info( 'params: ' +  x )
          logger.info('Going to try to connect to '+ desktopUrl)
          r = requests.post(desktopUrl, data=params, auth=(adminUser, adminPass ), verify=False)
#          logger.info('request ' + r.text )
#          logger.info('cookies ' + r.headers['Set-Cookie'] )
          if 'errors'.encode() in r.content:
             connected = False
          else:
            connected = True
            if connected:
                logger.info('We have connected to ' + url + '?desktop=admin')
                self.cook.load(r.headers['Set-Cookie'])
                security_token = json.loads(r.content[4:])['security_token']
                self.header['security_token'] = security_token
                self.header['Connection'] = 'keep-alive'
                self.header['Cookie'] = r.headers['Set-Cookie'] # 'JSESSIONID=' + self.cook['JSESSIONID'].value
            else:
                errors = json.loads(r.content[4:])['errors']
                logger.error('Failed to connect to ' +desktopUrl+ str(errors[0]))
                sys.exit('Not Able to connect to ' + url + '?desktop=admin' + '\n' + str(errors[0]))
        
        return self.header


    def addP8Repository(self, url='', repoName='', repoId='', serverURI='', osSymbolicName='', osDisplayName='', connectionPoint='', header=''):
        logger.info('addP8Repository()')
        addP8RepoURL = url + 'jaxrs/admin/configuration'
        json_post = {}
        json_post['name'] = osDisplayName
        json_post['objectStoreName'] = osSymbolicName
        # 
        json_post['id'] = osDisplayName
        json_post['objectStore'] = osSymbolicName
        json_post['serverName'] = serverURI
        json_post['type'] = 'p8'
        json_post['protocol'] = 'FileNetP8WSI'
        json_post['enableWSI'] = 'true'
        if connectionPoint != '':
            json_post['connectionPoint'] = connectionPoint
        else:
            json_post['connectionPoint'] = ''
        
        # additional configurations for objectstore.
        json_post['docNameProp'] = 'DocumentTitle'
        json_post['folderNameProp'] = 'FolderName'
        json_post['checkinAsMajorVersion'] = 'true'
        json_post['addAsMajorVersion'] = 'true'
        json_post['annotationSecurity'] = 'inherit'
        json_post['defaultSearchType'] = 'document'
        json_post['defaultSearchVersion'] = 'releasedversion'
        json_post['searchFilteredDocumentProperties'] = []
        json_post['searchFilteredFolderProperties'] = []
        json_post['folderSystemProperties'] = ['Creator', 'DateCreated', 'Id', 'PathName']
        json_post['searchMagazineDefCols'] = searchMagazineDefCols
        json_post['searchDefCols'] = searchDefCols 
        json_post = json.dumps(json_post)
        
        params = {}
        params['action'] = 'add'
        params['application'] = 'navigator'
        params['configuration'] = 'RepositoryConfig'
        params['desktop'] = 'admin'
        params['id'] = osDisplayName
        params['json_post'] = json_post
        params['update_list_configuration'] = 'ApplicationConfig'
        params['update_list_id'] = 'navigator'
        params['update_list_type'] = 'repositories'
        
#        logger.info( 'Going to create p8 repository with parameters: ' + json.dumps(params) )
        r = requests.post(addP8RepoURL, data=params, headers=header, verify=False)
        logger.info( 'Creation of p8 repository returned with status code: '+ str(r.status_code))
#        logger.info( 'Creation of p8 repository returned content: ')
#        logger.info( 'Creation of p8 repository returned content: ' + str( r.text) )
    
        return 
    
    
    
    def createPlugin(self, url='', pluginFilePath='', configurationStr='PluginConfig', enable=True, pluginOrder='1', userid='', header=''):
        logger.info( 'createPlugin()' )
        loadURL = ''
        requestURL = ''
        pluginNameStr = ''
        pluginVersionStr = ''
        pluginIdStr = ''
        pluginConfigClassStr = ''
        pluginConfigurationStr = ''
    
        loadURL = url + 'jaxrs/admin/loadPlugin'
        requestURL = url + 'jaxrs/admin/configuration'
    
        #header = {}
        json_params = {}
        json_params['application'] = 'navigator'
        json_params['desktop'] = 'admin'
        json_params['fileName'] = pluginFilePath
        
        r = requests.post(loadURL, data=json_params, headers=header, verify=False)
       
        response = json.loads(r.content[4:])
       
        pluginId = response['id']
        pluginIdStr = pluginId
        pluginConfigClassStr = response['configClass']
        pluginVersionStr = response['version']
        pluginNameStr = response['name']
        repositoryTypes = response['repositoryTypes']
        viewerDefs = response['viewerDefs']
        layouts = response['layouts']
        actions = response['actions']
        openActions = response['openActions']
        dependencies = response['dependencies']
        
        
        json_post = {}
        json_post['filename'] = pluginFilePath
        json_post['name'] = pluginNameStr
        json_post['id'] = pluginIdStr
        json_post['version'] = pluginVersionStr
        json_post['configClass'] = pluginConfigClassStr
        if enable:
            json_post['enabled'] = 'true'
        else:
            json_post['enabled'] = 'false'
    
        json_post['ordering'] = pluginOrder
        json_post['repositoryTypes'] = repositoryTypes
        json_post['viewerDefs'] = viewerDefs
        json_post['layouts'] = layouts
        json_post['actions'] = actions
        json_post['openActions'] = openActions
        json_post['dependencies'] = dependencies
        
        json_post = json.dumps(json_post)
        params = {}
        params['action'] = 'add'
        params['application'] = 'navigator'
        params['configuration'] = configurationStr
        params['desktop'] = 'admin'
        params['id'] = pluginIdStr
        params['json_post'] = json_post
        params['securityTopic'] = 'plugins.plugins'
        params['update_list_configuration'] = 'ApplicationConfig'
        params['update_list_id'] = 'navigator'
        params['update_list_type'] = 'plugins'
        params['userid'] = userid
        
        
        logger.info( 'Going to create plugin with parameters' + json.dumps(params) )
        r = requests.post(requestURL, data=params, headers=header, verify=False)
        logger.info( 'Creation of plugin returned a status code: '+ str(r.status_code) )
        logger.info( 'Creation of plugin returned content: ' + r.content )
       
       
       
        
        return

    def createDesktop(self, url='', desktopId='', desktopName='', desktopDesc='', applicationName='', repoList=[], defaultRepo='', featuresList=[], defaultFeature='', pluginLoadList=[], isDefault=False, userid='', headers=''):
        logger.info( 'createDesktop()' )
        setDefaultRepo = defaultRepo
        bannerBackgroudColor = ''
        bannerApplicationNameColor = ''
    
        requestURL = url + 'jaxrs/admin/updateAdminDesktopData'# 'jaxrs/admin/configuration'
        json_post_desktop_config= {}
        json_post = {}
        json_post['name'] = desktopName
        json_post['description'] = desktopDesc
        if isDefault:
            json_post['isDefault'] = 'Yes'
        else:
            json_post['isDefault'] = 'No'
    
        json_post['messageSearchUrl'] = ''
        json_post['viewer'] = 'default'
        json_post['fileIntoFolder'] = str('true')
        json_post['showSecurity'] = str('true')
        json_post['workflowNotification'] = str('true')
        json_post['applicationName'] = applicationName
        json_post['loginInformationUrl'] = ''
        json_post['passwordRulesUrl'] = ''
        json_post['loginLogoUrl'] = ''
        json_post['bannerLogoUrl'] = ''
        json_post['bannerBackgroudColor'] = bannerBackgroudColor
        json_post['bannerApplicationNameColor'] = bannerApplicationNameColor
        json_post['bannerMenuColor'] = '#FFFFFF'
        json_post['actionHandler'] = 'ecm.widget.layout.CommonActionsHandler'
        json_post['layout'] = 'ecm.widget.layout.NavigatorMainLayout'
    
        json_post['features'] = featuresList
        
        if 'workPane' in featuresList:
            json_post['workDefaultRepository'] = defaultRepo
            
       
        if defaultFeature != '':
            json_post['defaultFeature'] = defaultFeature
        
        json_post['otherFeaturesDefaultRepository'] = setDefaultRepo
        if pluginLoadList != '':
            json_post['pluginIds'] = pluginLoadList
            json_post['enableAllPlugins'] = str('false')
        
        json_post['showThumbnails'] = str('true')
        json_post['showGlobalToolbar'] = str('false')
        json_post['repositories'] = repoList
        json_post['defaultRepository'] = defaultRepo
        json_post['kcHelpText'] = ''
        json_post['kcHelpContext'] = ''
        json_post['kcHelpWelcome'] = ''
        json_post['GlobalToolbar'] = 'DefaultGlobalToolbar'
    
        json_post['GlobalToolbar'] = 'DefaultGlobalToolbar'
        json_post['OfficeDocumentListviewBrowseContextMenu'] = 'DefaultOfficeDocumentListviewBrowseContextMenu'
        json_post['OfficeFolderListviewBrowseContextMenu'] = 'DefaultOfficeFolderListviewBrowseContextMenu'
        json_post['OfficeFolderTreeviewBrowseContextMenu'] = 'DefaultOfficeFolderTreeviewBrowseContextMenu'
        json_post['OfficeRepositoryTreeviewBrowseContextMenu'] = 'DefaultOfficeRepositoryTreeviewBrowseContextMenu'
        json_post['OfficeSearchTreeviewBrowseContextMenu'] = 'DefaultOfficeSearchTreeviewBrowseContextMenu'
        json_post['OfficeDocumentVersionSeriesListviewContextMenu'] = 'DefaultOfficeDocumentVersionSeriesListviewContextMenu'
        json_post['AsyncTaskContextMenu'] = 'DefaultAsyncTaskContextMenu'
        json_post['AsyncTaskInstanceContextMenu'] = 'DefaultAsyncTaskInstanceContextMenu'
        json_post['ContentElementContextMenu'] = 'DefaultContentElementContextMenu'
        json_post['TeamspaceSubFolderContextMenuCM'] = 'DefaultTeamspaceSubFolderContextMenuCM'
        json_post['VersionsBoxContextMenu'] = 'DefaultVersionsBoxContextMenu'
        json_post['ItemContextMenu'] = 'DefaultItemContextMenu'
        json_post['VersionsCMContextMenu'] = 'DefaultVersionsCMContextMenu'
        json_post['VersionsContextMenu'] = 'DefaultVersionsContextMenu'
        json_post['TeamspaceSubFolderContextMenu'] = 'DefaultTeamspaceSubFolderContextMenu'
        json_post['FolderContextMenu'] = 'DefaultFolderContextMenu'
        json_post['MixItemsContextMenu'] = 'DefaultMixItemsContextMenu'
        json_post['MultipleAsyncTasksContextMenu'] = 'DefaultMultipleAsyncTasksContextMenu'
        json_post['RecurringAsyncTaskContextMenu'] = 'DefaultRecurringAsyncTaskContextMenu'
        json_post['TeamspaceSearchTemplateContextMenu'] = 'DefaultTeamspaceSearchTemplateContextMenu'
        json_post['SelectObjectItemContextMenu'] = 'DefaultSelectObjectItemContextMenu'
        json_post['SelectObjectFolderContextMenu'] = 'DefaultSelectObjectFolderContextMenu'
        json_post['SystemItemContextMenu'] = 'DefaultSystemItemContextMenu'
        json_post['TeamspaceItemContextMenu'] = 'DefaultTeamspaceItemContextMenu'
        json_post['FolderContextMenuCM'] = 'DefaultFolderContextMenuCM'
        json_post['FavoriteFolderContextMenuCM'] = 'DefaultFavoriteFolderContextMenuCM'
        json_post['AttachmentItemContextMenuCM'] = 'DefaultAttachmentItemContextMenuCM'
        json_post['AttachmentFolderContextMenuCM'] = 'DefaultAttachmentFolderContextMenuCM'
        json_post['WorkItemDocumentContextMenu'] = 'DefaultWorkItemDocumentContextMenu'
        json_post['WorkItemFolderContextMenu'] = 'DefaultWorkItemFolderContextMenu'
        json_post['InbasketToolbar'] = 'DefaultInbasketToolbar'
        json_post['AsyncTaskToolbar'] = 'DefaultAsyncTaskToolbar'
        json_post['ContentElementToolbar'] = 'DefaultContentElementToolbar'
        json_post['ContentListToolbar'] = 'DefaultContentListToolbar'
        json_post['SelectObjectToolbar'] = 'DefaultSelectObjectToolbar'
        json_post['VersionsToolbar'] = 'DefaultVersionsToolbar'
        json_post['ManageEntryTemplatesListToolbar'] = 'DefaultManageEntryTemplatesListToolbar'
        json_post['FavoritesContextMenu'] = 'DefaultFavoritesContextMenu'
        json_post['FavoriteItemContextMenu'] = 'DefaultFavoriteItemContextMenu'
        json_post['FavoriteFolderContextMenu'] = 'DefaultFavoriteFolderContextMenu'
        json_post['FavoriteSearchTemplateContextMenu'] = 'DefaultFavoriteSearchTemplateContextMenu'
        json_post['FavoriteSystemItemContextMenu'] = 'DefaultFavoriteSystemItemContextMenu'
        json_post['FavoriteTeamspaceContextMenu'] = 'DefaultFavoriteTeamspaceContextMenu'
        json_post['BannerToolsContextMenu'] = 'DefaultBannerToolsContextMenu'
        json_post['BannerUserSessionContextMenu'] = 'DefaultBannerUserSessionContextMenu'
        json_post['TeamspaceFolderContextMenu'] = 'DefaultTeamspaceFolderContextMenu'
        json_post['EntryTemplateContextMenu'] = 'DefaultEntryTemplateContextMenu'
        json_post['ObjectStoreFolderContextMenu'] = 'DefaultObjectStoreFolderContextMenu'
        json_post['SearchTemplateBookmarkContextMenu'] = 'DefaultSearchTemplateBookmarkContextMenu'
        json_post['SearchTemplateContextMenu'] = 'DefaultSearchTemplateContextMenu'
        json_post['SearchSearchTemplateContextMenu'] = 'DefaultSearchSearchTemplateContextMenu'
        json_post['TeamspaceContextMenu'] = 'DefaultTeamspaceContextMenu'
        json_post['TeamspaceTemplateContextMenu'] = 'DefaultTeamspaceTemplateContextMenu'
        json_post['FavoritesToolbar'] = 'DefaultFavoritesToolbar'
        json_post['MyCheckoutsToolbar'] = 'DefaultMyCheckoutsToolbar'
        json_post['MySyncedFilesToolbar'] = 'DefaultMySyncedFilesToolbar'
        json_post['AddDocumentAttachmentContextMenu'] = 'DefaultAddDocumentAttachmentContextMenu'
        json_post['AddFolderAttachmentContextMenu'] = 'DefaultAddFolderAttachmentContextMenu'
        json_post['AttachmentItemContextMenu'] = 'DefaultAttachmentItemContextMenu'
        json_post['AttachmentFolderContextMenu'] = 'DefaultAttachmentFolderContextMenu'
        json_post['UserQueueContextMenu'] = 'DefaultUserQueueContextMenu'
        json_post['ProcessQueueContextMenu'] = 'DefaultProcessQueueContextMenu'
        json_post['TrackerQueueContextMenu'] = 'DefaultTrackerQueueContextMenu'
        json_post['StepProcessorToolbarP8'] = 'DefaultStepProcessorToolbarP8'
        json_post['InbasketToolbarP8'] = 'DefaultInbasketToolbarP8'
        json_post['AttachmentToolbar'] = 'DefaultAttachmentToolbar'
        json_post['OfficeDocumentFavoritesListviewContextMenu'] = 'DefaultOfficeDocumentFavoritesListviewContextMenu'
        json_post['OfficeFolderFavoritesListViewContextMenu'] = 'DefaultOfficeFolderFavoritesListViewContextMenu'
        json_post['OfficeFolderFavoritesTreeviewContextMenu'] = 'DefaultOfficeFolderFavoritesTreeviewContextMenu'
        json_post['OfficeDocumentCheckoutsListviewContextMenu'] = 'DefaultOfficeDocumentCheckoutsListviewContextMenu'
        json_post['OfficeDocumentRecentlyUsedListviewContextMenu'] = 'DefaultOfficeDocumentRecentlyUsedListviewContextMenu'
        json_post['MySyncedFilesContextMenu'] = 'DefaultMySyncedFilesContextMenu'
        json_post['MySyncedFilesItemContextMenu'] = 'DefaultMySyncedFilesItemContextMenu'
        json_post['MySyncedFilesFolderContextMenu'] = 'DefaultMySyncedFilesFolderContextMenu'
        json_post['MySyncedFilesTeamspaceContextMenu'] = 'DefaultMySyncedFilesTeamspaceContextMenu'
        json_post['OfficeAddToolbar'] = 'DefaultOfficeAddToolbar'
        json_post['OfficeRibbonToolbar'] = 'DefaultOfficeRibbonToolbar'
        json_post['OfficeCustomToolbar'] = 'DefaultOfficeCustomToolbar'
        json_post['OfficeEditToolbar'] = 'DefaultOfficeEditToolbar'
        json_post['OfficeLoginToolbar'] = 'DefaultOfficeLoginToolbar'
        json_post['OfficeOpenToolbar'] = 'DefaultOfficeOpenToolbar'
        json_post['OfficeOutlookAddToolbar'] = 'DefaultOfficeOutlookAddToolbar'
        json_post['OfficeResourcesToolbar'] = 'DefaultOfficeResourcesToolbar'
        json_post['OfficeSaveToolbar'] = 'DefaultOfficeSaveToolbar'
        json_post['OfficeTeamspacesToolbar'] = 'DefaultOfficeTeamspacesToolbar'
        json_post['OfficeWorkflowToolbar'] = 'DefaultOfficeWorkflowToolbar'
        json_post['OfficeSearchFavoritesListviewContextMenu'] = 'DefaultOfficeSearchFavoritesListviewContextMenu'
        json_post['OfficeSearchFavoritesTreeviewContextMenu'] = 'DefaultOfficeSearchFavoritesTreeviewContextMenu'
        json_post['OfficeDocumentsSearchResultsListviewContextMenu'] = 'DefaultOfficeDocumentsSearchResultsListviewContextMenu'
        json_post['OfficeFoldersSearchResultsListviewContextMenu'] = 'DefaultOfficeFoldersSearchResultsListviewContextMenu'
        json_post['OfficeSearchSavedSearchListviewContextMenu'] = 'DefaultOfficeSearchSavedSearchListviewContextMenu'
        json_post['SearchResultsToolbar'] = 'DefaultSearchResultsToolbar'
        json_post['OfficeTeamspaceFavoritesListviewContextMenu'] = 'DefaultOfficeTeamspaceFavoritesListviewContextMenu'
        json_post['OfficeTeamspaceFavoritesTreeviewContextMenu'] = 'DefaultOfficeTeamspaceFavoritesTreeviewContextMenu'
        json_post['OfficeTeamspaceListviewContextMenu'] = 'DefaultOfficeTeamspaceListviewContextMenu'
        json_post['OfficeTeamspaceBrowseTreeviewContextMenu'] = 'DefaultOfficeTeamspaceBrowseTreeviewContextMenu'
        json_post['TeamspaceContentListToolbar'] = 'DefaultTeamspaceContentListToolbar'
        json_post['ManageTeamspacesListToolbar'] = 'DefaultManageTeamspacesListToolbar'
        json_post['ManageTemplatesListToolbar'] = 'DefaultManageTemplatesListToolbar'
        json_post['TeamspacesListToolbar'] = 'DefaultTeamspacesListToolbar'
        json_post['TeamspaceToolbar'] = 'DefaultTeamspaceToolbar'
        json_post['TemplatesListToolbar'] = 'DefaultTemplatesListToolbar'
        json_post['OfficeDocumentWorkflowAttachmentListviewContextMenu'] = 'DefaultOfficeDocumentWorkflowAttachmentListviewContextMenu'
        json_post['OfficeDocumentWorkflowReferenceListviewContextMenu'] = 'DefaultOfficeDocumentWorkflowReferenceListviewContextMenu'
        
           
        # json_post = json.dumps(json_post)
        json_post_desktop_config['desktopConfig'] = json_post
        json_post_desktop_features_data = []
        for x in featuresList:
            if 'favorites' in x or 'browsePane' in x or 'searchPane' in x or 'workPane' in x:
                json_fd = {}
                json_fd['id'] = desktopId+'.'+x
                json_fd['name'] = 'DesktopFeatureConfig'
                if 'favorites' in x:
                    json_att = {}
                    json_att['showMyCheckouts'] = 'false'
                    json_att['showDocumentInfoPane'] = 'true'
                    json_att['documentInfoPaneDefaultOpen'] = 'false'
                    json_att['documentInfoPaneOpenOnSelection'] = 'true'
                    json_att['showRepositories'] = repoList 
                    json_att['defaultRepository'] = defaultRepo 
                    json_fd['_attributes'] = json_att
                if 'browsePane' in x:
                    json_att = {}
                    json_att['showTreeView'] = 'true'
                    json_att['showDocumentInfoPane'] = 'true'
                    json_att['documentInfoPaneDefaultOpen'] = 'false'
                    json_att['documentInfoPaneOpenOnSelection'] = 'true'
                    json_att['showRepositories'] = repoList 
                    json_att['showMyCheckouts'] = 'false' 
                    json_att['defaultRepository'] = defaultRepo 
                    json_att['showViews'] = ['detail', 'magazine', 'filmstrip']
                    json_fd['_attributes'] = json_att
                if 'searchPane' in x:
                    json_att = {}
                    json_att['showDocumentInfoPane'] = 'true'
                    json_att['documentInfoPaneDefaultOpen'] = 'false'
                    json_att['documentInfoPaneOpenOnSelection'] = 'true'
                    json_att['showRepositories'] = repoList  
                    json_att['defaultRepository'] = defaultRepo 
                    json_fd['_attributes'] = json_att
                if 'workPane' in x:
                    json_att = {}
                    json_att['showTreeView'] = 'false'
                    json_att['shoMyCheckouts'] = 'false'
                    json_att['showDocumentInfoPane'] = 'true'
                    json_att['documentInfoPaneDefaultOpen'] = 'false'
                    json_att['documentInfoPaneOpenOnSelection'] = 'true'
                    json_att['showRepositories'] = repoList  
                    json_att['defaultRepository'] = defaultRepo 
                    json_fd['_attributes'] = json_att
                    
                json_post_desktop_features_data.append(json_fd)
        
        
        json_all = {}
        json_all['desktopConfig'] = json_post
        json_all['desktopFeaturesData'] = json_post_desktop_features_data
        
        
        json_params = {}
        json_params['action'] = 'add'
        json_params['application'] = 'navigator'
        json_params['desktop'] = 'admin'
        '''
        New stuff
        '''
        json_params['userid'] = userid
        json_params['desktopId'] = desktopId
        json_params['login_desktop'] = 'admin'
        
        ''''
        New stuff
        '''
        json_params['json_post'] = json.dumps( json_all )
        logger.info('Going to create desktop '+ desktopName)
#        logger.info('Payload: '+ str( json_params ))
        logger.info('url :' + str( requestURL ) ) 
        r = requests.post(requestURL, data=json_params, headers=headers, verify=False)
        
#        logger.info( 'createDesktop: ' + str( r.text )  )
        if 'errors' in r.text:
            logger.error('Failed to create Desktop' + '\n' + r.text)
            sys.exit('Failed to create Desktop' + '\n' + r.text)
        else:
            logger.info( 'Created Desktop '+desktopName )
#            logger.info( r.text )
            
        
        
        return

    def getP8Repo(self,url='', serverURI='', osSymbolicName='', headers=''):
#        logger.info( 'getP8Repo()' )
        repoList = json.loads( self.listRepositories(url=url, headers=headers))
        repository = []
#        logger.info( 'getP8Repo : ' + str( repoList )  ) 
        if repoList != '':
            for obj in repoList:
                if 'type' in obj and obj['type'] == 'p8' and 'serverName' in obj and obj['serverName'] == serverURI and 'objectStore' in obj and obj['objectStore'] == osSymbolicName:
                    repository.append(obj['name'])
#                    logger.info(obj['name'])
                    break
        
        logger.info('getP8Repo : ' + str(repository ) )
        return repository

    def listRepositories(self,url='', headers=''):
        logger.info( 'listRepositories()' )
        requestURL = url + 'jaxrs/admin/configuration'
        
        params = {}
        params['action'] = 'list'
        params['application'] = 'navigator'
        params['configuration'] = 'ApplicationConfig'
        params['desktop'] = 'admin'
        params['id'] = 'navigator'
        params['sorted'] = 'true'
        params['type'] = 'repositories'

        r = requests.post(requestURL, data=params, headers=headers, verify=False)

#        logger.info(  'listRepositories : '  + str( r.text ) )
        content = json.loads(r.text[4:])
#        logger.info(  'listRepositories : '  + str( r.text ) )
        for x in content:
#         logger.info( 'listRepositories x : ' + x ) 
#          logger.info( 'listRepositories content[list] : ' + str( content['list'] ) )
          if 'list' in content:
            repoList = content['list']
          else: 
            repoList = []

        return json.dumps(repoList)

    def checkDesktop(self, url = '', userid = '', desktopCheck = '', headers = ''):
        requestURL = url +'jaxrs/admin/configuration'
        data = {}
        data['action'] = 'list'
        data['id'] = 'navigator'
        data['userid'] = userid
        data['type'] = 'desktops'
        data['sorted'] = 'true'
        data['configuration'] = 'ApplicationConfig'
        data['login_desktop'] = 'admin'
        data['application'] = 'navigator'
        data['securityTopic'] = 'desktop.desktop'
        data['desktop'] = 'admin'
        
        r = requests.post(requestURL, data=data, headers=headers, verify=False)
        list = json.loads( r.content[4:] )['list']
        created = False
        for x in list:
            if x['id'] == desktopCheck:
                created = True
                break

        return created
