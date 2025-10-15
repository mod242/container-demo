### ICNADMIN

# To run for ECM Content desktop:
	python icndefaultdriver.py --icnURL `http://{host_name}:{port}/navigator/` --icnAdmin `icnadmin` --icnPassd `icnpassword` --ceURL `http://{host_name}:{port}/wsi/FNCEWS40MTOM` --objStoreName `OBJECT_STORE` --featureList `browsePane searchPane favorites workPane`  --defaultFeature `browsePane`  --desktopId `DESKTOP_ID` --desktopName `SOME NAME FOR THE DESKTOP` --desktopDesc `SOME DESCRIPTION FOR THE DESKTOP` --applicationName `ANY APPLICATION NAME` --defaultRepo `DEFAULT_REPO_NAME SHOULD BE THE SAME AS THE DISPLAY NAME FOR THE REPO` --connectionPoint `CONNECTION_POINT:ISOLATED_REGION_NUMBER` --osDisplayName DEMODISPLAY

### Example:
	python icndefaultdriver.py --icnURL http://localhost:9081/navigator/ --icnAdmin CEAdmin --icnPassd Genius1 --ceURL http://localhost:9080/wsi/FNCEWS40MTOM --objStoreName DEMO --featureList browsePane searchPane favorites workPane  --defaultFeature browsePane  --desktopId demo --desktopName ECM Container Demo --desktopDesc Default desktop for Demo Container configuration --applicationName ECM Container Demo --defaultRepo DEMODISPLAY --connectionPoint PE_CONN_2:2  --osDisplayName DEMODISPLAY
