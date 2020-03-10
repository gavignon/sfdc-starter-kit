/**
* @author Gil Avignon
* @date 25/07/2018
* @description Helper that manages callouts to external systems (Using Callout Settings)
* @group Web Service
*/
public class WS_Helper{
    private static final String CLASS_NAME = WS_Helper.class.getName();

    private static Map<String, CalloutSetting__mdt> mapCalloutSettingsByFlow;
    private static Map<String, CalloutSetting__mdt> mapCalloutSettingsByFlowDefault;
    private static CalloutSetting__mdt currentCalloutSetting;
    private static String authToken;
    public static String testAuthToken;
    private static String tokenUrl;
    private static String auId;
    private static String usFedIde;
    private static Boolean debugLogs = false;
    private static Boolean isRefreshToken = false;
    private static String contextApexClass;
    private static String contextApexMethod;

    public static Boolean testMock = false;

    static{
        // Init
        mapCalloutSettingsByFlow = new Map<String, CalloutSetting__mdt>();
        mapCalloutSettingsByFlowDefault = new Map<String, CalloutSetting__mdt>();

        // Get Environment name
        String defaultSetting = UTIL_Constants.ORG_NAME_DEFAULT;
        String orgName = '';
        String username = UserInfo.getUserName();
        orgName = username.substringAfterLast('.');
        if(username.endsWith ('.com')){
            orgName = UTIL_Constants.ORG_NAME_PRD;
        }
        if(Test.isRunningTest()){
            orgName = UTIL_Constants.ORG_NAME_DEV;
        }

        // Get authentication provider
        AuthConfig ac = [SELECT Id FROM AuthConfig WHERE Type = 'Org'];
        AuthConfigProviders acp = [SELECT Id, AuthProviderId FROM AuthConfigProviders WHERE AuthConfigId  =: ac.Id];
        AuthProvider authProv = [SELECT TokenUrl FROM AuthProvider WHERE Id = :acp.AuthProviderId LIMIT 1];
        if(authProv != null){
            tokenUrl = authProv.TokenUrl;
        }
        auId = acp.AuthProviderId  + '';
        if(auId.length() > 15){
            auId = auId.substring(0, 15);
        }

        // Get current user
        User us = [SELECT Id, FederationIdentifier FROM User WHERE Id =: UserInfo.getUserId()];
        usFedIde = us.FederationIdentifier;

        // Get Cached token
        Map<String, String> accessTokenMap = Auth.AuthToken.getAccessTokenMap(auId, 'Open ID connect');
        authToken = accessTokenMap.get(usFedIde);

        // Get Callout Setting Metadata By Flow name
        List<CalloutSetting__mdt> cmdtList = [SELECT Id, Method__c, MockResponse__c, Environment__c, APIName__c,
                Mock__c, Operation__c, BasePath__c, Authentication__c, Username__c, Password__c, APIKey__c,
                Debug__c  FROM CalloutSetting__mdt
        WHERE Active__c = TRUE AND (Environment__c =:orgName OR Environment__c =:defaultSetting)];
        for(CalloutSetting__mdt cm: cmdtList){
            if(cm.Environment__c == defaultSetting){
                mapCalloutSettingsByFlowDefault.put(cm.APIName__c + cm.Operation__c, cm);
            }else{
                mapCalloutSettingsByFlow.put(cm.APIName__c + cm.Operation__c, cm);
            }
        }
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Main method that orchestrates the callout to a web service
    * @param flowName API Flow name
    * @param method HTTP Request method
    * @param params HTTP Request parameters
    * @param body HTTP Request body
    * @param entityId Current main entity (used to tracability in header)
    * @return String Web service response string (JSON)
    */
    public static HttpResponse callWebservice(String apexClass, String apexMethod, String flowName, String operation, Map<String, String> pathParams, Map<String, String> params, String body, Id entityId){
        if(Test.isRunningTest()){
            authToken = testAuthToken;
        }

        // Init
        contextApexClass = apexClass;
        contextApexMethod = apexMethod;
        currentCalloutSetting =(mapCalloutSettingsByFlow.containskey(flowName + operation)? mapCalloutSettingsByFlow.get(flowName + operation):mapCalloutSettingsByFlowDefault.get(flowName + operation));

        if(currentCalloutSetting != null){
            debugLogs = currentCalloutSetting.Debug__c;
        }

        // Manage Mock
        if((currentCalloutSetting.Mock__c && !Test.isRunningTest()) || (Test.isRunningTest() && testMock)){
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setStatus('success');
            mockResponse.setStatusCode(200);

            mockResponse.setBody(currentCalloutSetting.MockResponse__c);
            return mockResponse;
        }else{
            // Manage Authentication
            String authHeaderType = '';
            String authHeaderValue = '';
            if(currentCalloutSetting.Authentication__c == UTIL_Constants.AUTHENTICATION_TYPE_ACCESS_TOKEN){
                // Manage Access Token Authentication
                Boolean tokenHasExpired = false;
                if(authToken != null){
                    tokenHasExpired = tokenExpires(authToken);
                }

                if((authToken == null) || tokenHasExpired){
                    authToken = getAuthToken(tokenHasExpired);
                }

                authHeaderType = UTIL_Constants.REQUEST_HEADER_KEY;
                authHeaderValue = 'Bearer ' + authToken;
            }else if(currentCalloutSetting.Authentication__c == UTIL_Constants.AUTHENTICATION_TYPE_API_KEY){
                // Manage API Key Authentication
                authHeaderType = 'KeyId';
                authHeaderValue = currentCalloutSetting.APIKey__c;
            }
            else if(currentCalloutSetting.Authentication__c == UTIL_Constants.AUTHENTICATION_TYPE_BASIC){
                // Manage Basic Authentication
                authHeaderType = 'Authorization';
                Blob credentialsBlob = Blob.valueOf(currentCalloutSetting.Username__c + ':' + currentCalloutSetting.Password__c);
                authHeaderValue = 'Basic ' + EncodingUtil.base64Encode(credentialsBlob);
            }

            // Construct endpoint from Callout Setting
            String endpoint = currentCalloutSetting.BasePath__c + currentCalloutSetting.Operation__c;
            // Perform the callout
            return callout(endpoint, authHeaderType, authHeaderValue, pathParams, params, body, entityId);
        }
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Manage the token expiration
    * @param token Authentication Token
    * @return Boolean true if the token is expired
    */
    public static Boolean tokenExpires(String token){
        String tokenEncodedPayload = token.substringBetween('.', '.');
        Blob blobPayload = EncodingUtil.base64Decode(tokenEncodedPayload);

        String tokenPayload = blobPayload.toString();

        Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(tokenPayload);
        String expirationTimestamp = String.valueOf((Integer)payloadMap.get('exp')) + '000';
        if(expirationTimestamp != null){
            Datetime expirationDate = Datetime.newInstance(Long.valueOf(expirationTimestamp));
            Datetime currentDate = Datetime.now();

            return currentDate > expirationDate;
        }else{
            return false;
        }
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Retrieve the Authentication Token
    * @param token Current token (for Refresh token process only)
    * @param tokenHasExpired Boolean true if the token has expired
    * @return String Retrieved token
    */
    private static String getAuthToken(Boolean tokenHasExpired){
        String accessToken = '';
        String authError = '';

        // TODO: Refactor
        Boolean isUserAPI = FeatureManagement.checkPermission('CPE01_IntegrationByPass');
        // if(isUserAPI){
        //     User currentUser = [SELECT Id, AccessToken__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        //     if(currentUser.AccessToken__c != null){
        //         return currentUser.AccessToken__c;
        //     }
        // }

        // Manage refresh token
        if(tokenHasExpired){
            UTIL_Logger.debug('Refresh Token', 'auId: ' + auId + ' authToken: ' + authToken,CLASS_NAME, 'getAuthToken', null);

            Map<String, String> refreshToken = Auth.AuthToken.refreshAccessToken(auId, 'Open ID connect', authToken);
            accessToken = refreshToken.get('AccessToken');
            authError = refreshToken.get('RefreshError');
            isRefreshToken = true;
        }else{
            Map<String, String> accessTokenMap = Auth.AuthToken.getAccessTokenMap(auId, 'Open ID connect');
            accessToken = accessTokenMap.get(usFedIde);
        }

        if(Test.isRunningTest()){
            return accessToken;
        }

        // Not connected from SSO
        if(!isRefreshToken && accessToken == null){
            LogEvent__e logEvent = UTIL_Logger.logEvent(currentCalloutSetting.APIName__c, Label.C3S_ERR_LBL_NotLoggedWithSSO, CLASS_NAME, 'getAuthToken', tokenUrl, null, null);
            throw new HelperException('Error', Label.C3S_ERR_LBL_NotLoggedWithSSO, null, logEvent.Identifier__c);
        }
        // Refresh returns null
        if(isRefreshToken && accessToken == null){
            LogEvent__e logEvent = UTIL_Logger.logEvent(currentCalloutSetting.APIName__c, Label.C3S_ERR_SSORefresh + ': ' + authError, CLASS_NAME, 'getAuthToken', tokenUrl, null, null);
            throw new HelperException('Error', Label.C3S_ERR_LBL_NotLoggedWithSSO, null, logEvent.Identifier__c);
        }

        return accessToken;
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Construct and send the HTTP Request to the endpoint
    * @param endpoint WS Endpoint
    * @param method HTTP Request method
    * @param authHeader HTTP Request authentication header
    * @param params HTTP Request parameters
    * @param body HTTP Request body
    * @param entityId Current main entity (used to tracability in header)
    * @return String HTTP Response string
    */
    private static HttpResponse callout(String endpoint, String authHeaderType, String authHeaderValue, Map<String, String> pathParams, Map<String, String> params, String body, Id entityId){

        // Manage Path Parameters
        if(pathParams != null){
            for(String pathTemplate : pathParams.keySet()){
                String newPathTemplate = pathTemplate.replaceAll('\\{', '\\\\{');
                newPathTemplate = newPathTemplate.replaceAll('\\}', '\\\\}');
                endpoint = endpoint.replaceAll(newPathTemplate, pathParams.get(pathTemplate));
            }
        }

        // Manage URLEncoded Parameters
        if(params!= null){
            String paramString = '';

            for(String paramName : params.keySet()){
                if(paramString != ''){
                    paramString += '&';
                }else{
                    paramString += '?';
                }
                if(params.get(paramName).contains('&'+paramName+'=')){
                    List<String> paramListValues = params.get(paramName).split('&'+paramName+'=');
                    paramString += paramName + '=';
                    for(Integer i = 0; i < paramListValues.size(); i++){
                        if(i > 0){
                            paramString += '&'+paramName+'=';
                        }
                        paramString += EncodingUtil.urlEncode(paramListValues[i], 'UTF-8');

                    }
                }else{
                    paramString += paramName + '=' + EncodingUtil.urlEncode(params.get(paramName), 'UTF-8');
                }
            }
            if(paramString != ''){
                endpoint += paramString;
            }
        }

        HttpRequest req = new HttpRequest();

        req.setEndpoint(endpoint);

        req.setMethod(currentCalloutSetting.Method__c);
        req.setHeader(authHeaderType, authHeaderValue);

        // Header trace logs
        req.setHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ORG, UserInfo.getOrganizationId());
        req.setHeader(UTIL_Constants.REQUEST_HEADER_TRACE_USER, UserInfo.getUserId());
        if(entityId != null){
            req.setHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ENTITY, entityId);
        }
        req.setHeader('X-SFDC-RefreshToken', String.valueOf(isRefreshToken));

        if(body != null){
            req.setBody(body);
        }

        Http http = new Http();
        HttpResponse response;

        try{
            response = http.send(req);

            if(response.getStatusCode() > 200 && response.getStatusCode() < 300){
                if(debugLogs){
                    UTIL_Logger.logEvent(currentCalloutSetting.APIName__c, contextApexClass, contextApexMethod, req, response, debugLogs);
                }
            }else{
                LogEvent__e logEvent = UTIL_Logger.logEvent(currentCalloutSetting.APIName__c, contextApexClass, contextApexMethod, req, response, false);
                throw new HelperException('Callout', 'Error ' + response.getStatusCode() + ': ' + response.getStatus(), response, logEvent.Identifier__c);
            }
        }catch(CalloutException e){
            LogEvent__e logEvent = UTIL_Logger.logEventFromException(currentCalloutSetting.APIName__c, e, contextApexClass, contextApexMethod, endpoint + pathParams, entityId, authHeaderValue);
            throw new HelperException('Callout', e.getMessage(), null, logEvent.Identifier__c);
        }

        return response;
    }

    public class HelperException extends Exception {
        public String message;
        public String type;
        public HttpResponse response;
        public String logId;
        public HelperException(String type, String message, HttpResponse response, String logId){
            this.type = type;
            this.message = message;
            this.response = response;
            this.logId = logId;
        }
    }
}
