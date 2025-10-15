'''
Created on Oct 27, 2017

@author: Jesse Rodriguez 'rodrigje@us.ibm.com'
'''

import argparse

from navigator import Navigator


def readConfigurations(args):
    '''
    Navigator
    '''
    global nexusURL
    global nexusAdmin
    global nexusPassd
    global ceURI
    global objectStoreName
    global featuresList
    global defaultFeature
    global pluginLoadList
    global pluginFilePath
    global desktopId
    global desktopName
    global desktopDesc
    global applicationName
    global defaultRepo
    global connectionPoint
    global osDisplayName
    global isDefault
    
    
    nexusURL=args.icnURL
    nexusAdmin=args.icnAdmin
    nexusPassd=args.icnPassd
    ceURI=args.ceURL
    objectStoreName=args.objStoreName
    featuresList= args.featureList
    defaultFeature=args.defaultFeature
    pluginLoadList=args.pluginLoadList
    pluginFilePath=args.pluginFilePath
    desktopId=args.desktopId
    desktopName=' '.join(map(str, args.desktopName))
    desktopDesc=' '.join(map (str, args.desktopDesc ))
    applicationName=' '.join(map(str, args.applicationName))
    defaultRepo=args.defaultRepo
    connectionPoint = args.connectionPoint
    osDisplayName = args.osDisplayName
    if 'false' in args.isDefault.lower():
        isDefault = False
    else:
        isDefault = True
    
    
    
    return

def createICNDesktop():
    icn = Navigator()
    
    authHeader = icn.getAuthHeader(adminUser=nexusAdmin, adminPass=nexusPassd)

    header = icn.testLogin(url=nexusURL, authHeaders=authHeader, adminUser=nexusAdmin, adminPass=nexusPassd)
    icn.addP8Repository(url=nexusURL, repoName=objectStoreName, repoId=objectStoreName, serverURI=ceURI, osSymbolicName=objectStoreName, osDisplayName=osDisplayName, connectionPoint=connectionPoint, header=header)
    if pluginFilePath != '':
        icn.createPlugin(url=nexusURL, pluginFilePath=pluginFilePath, configurationStr='PluginConfig', enable=True, pluginOrder='1', userid=nexusAdmin, header=header)

    repoList = icn.getP8Repo(url=nexusURL, serverURI=ceURI, osSymbolicName=objectStoreName,  headers=header)
    
    
    icn.createDesktop(url=nexusURL, desktopId=desktopId, desktopName=desktopName, desktopDesc=desktopDesc, applicationName=applicationName, repoList=repoList, defaultRepo=defaultRepo, featuresList=featuresList, defaultFeature=defaultFeature, pluginLoadList=pluginLoadList, isDefault=isDefault, userid=nexusAdmin, headers=header)
        
    return

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--icnURL', required=True)
    parser.add_argument('--icnAdmin', required=True)
    parser.add_argument('--icnPassd', required=True)
    parser.add_argument('--ceURL', required=True)
    parser.add_argument('--objStoreName', required=True)
    parser.add_argument('--featureList', required=True, nargs='*')
    parser.add_argument('--defaultFeature',required=True)
    parser.add_argument('--pluginLoadList', default='')
    parser.add_argument('--pluginFilePath', default='')
    parser.add_argument('--desktopId', required=True)
    parser.add_argument('--desktopName', required=True, nargs='*')
    parser.add_argument('--desktopDesc', required=True, nargs='*')
    parser.add_argument('--applicationName', required=True, nargs='*')
    parser.add_argument('--defaultRepo', required=True)
    parser.add_argument('--connectionPoint', default='')
    parser.add_argument('--osDisplayName', required=True)
    parser.add_argument('--isDefault', required=True)
    
    
    
    
    args = parser.parse_args()
    readConfigurations(args=args)
    createICNDesktop()

    return


if __name__ == '__main__':
    main()

