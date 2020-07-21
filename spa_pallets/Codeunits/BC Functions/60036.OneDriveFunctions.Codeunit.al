codeunit 60036 "OneDrive Functions"
{
    procedure GetBearerToken(): Text
    var
        lClient: HttpClient;
        lResponse: HttpResponseMessage;
        lContent: HttpContent;
        lHeaders: HttpHeaders;
        lUrl: Text;
        lJsonObj: JsonObject;
        lJsonToken: JsonToken;
        Token: text;
        lClientID: text[250];
        lSecret: text[250];
        BaseTxt: Text[1024];
        APITokenLocal: Text;
        lDirectory: Text;
        PalletProcessSetup: Record "Pallet Process Setup";
    begin
        PalletProcessSetup.get;
        lDirectory := PalletProcessSetup."OneDrive Directory ID";
        lUrl := 'https://login.microsoftonline.com/' + lDirectory + '/oauth2/v2.0/token';
        lClientID := PalletProcessSetup."OneDrive Client ID";
        lSecret := PalletProcessSetup."OneDrive Client Secret";
        BaseTxt := 'grant_type=client_credentials&client_id=' + lClientID + '&client_secret=' + lSecret + '&scope=https://graph.microsoft.com/.default';
        lContent.Clear();
        lContent.WriteFrom(BaseTxt);
        lHeaders.Clear();
        lContent.GetHeaders(lHeaders);
        lHeaders.Remove('Content-Type');
        lHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
        lContent.GetHeaders(lHeaders);
        if lClient.Post(lUrl, lContent, lResponse) then begin
            lResponse.Content().ReadAs(Token);
            lJsonObj.ReadFrom(Token);
            lJsonObj.Get('access_token', lJsonToken);
            lJsonToken.WriteTo(APITokenLocal);
            APITokenLocal := DelChr(APITokenLocal, '=', '"');
            Exit(APITokenLocal);
        end
        else
            error('API Token Request failed');
    end;


    Procedure CreateUploadURL(FileName: Text; BearerToken: Text; OutStr: OutStream): Text
    var
        lUrl: Text;
        Bearer: Text;
        lHeaders: HttpHeaders;
        BodyContent: HttpContent;
        lContent: HttpContent;
        lreqHeaders: HttpHeaders;
        lclient: HttpClient;
        lRequest: HttpRequestMessage;
        lResponse: HttpResponseMessage;
        BaseTxt: Text;
        lJsonObj: JsonObject;
        lJsonToken: JsonToken;
        WebUrl: Text;
        PalletProcessSetup: Record "Pallet Process Setup";

    begin
        PalletProcessSetup.get;
        lUrl := 'https://graph.microsoft.com/v1.0/drives/' + PalletProcessSetup."OneDrive Drive ID" + '/root:/' + FileName + ':/content';
        Bearer := 'Bearer ' + BearerToken;
        lHeaders.Clear();
        lContent.GetHeaders(lHeaders);
        lHeaders.Remove('Content-Type');
        lHeaders.Add('Content-Type', 'text/plain');
        lreqHeaders := lClient.DefaultRequestHeaders();
        lreqHeaders.Add('Authorization', Bearer);
        lreqHeaders.Remove('Accept');
        lreqHeaders.Add('Accept', 'text/plain');
        lContent.WriteFrom('ABCDEFG');
        lRequest.GetHeaders(lReqHeaders);
        lContent.GetHeaders(lHeaders);
        lRequest.Method := 'PUT';
        lRequest.SetRequestUri(lUrl);
        lRequest.GetHeaders(lReqHeaders);
        if lClient.Send(lRequest, lResponse) then begin
            lResponse.Content().ReadAs(BaseTxt);
            message(BaseTxt);
            lJsonObj.ReadFrom(BaseTxt);
            if lResponse.IsSuccessStatusCode() then begin
                lJsonObj.Get('uploadUrl', lJsonToken);
                lJsonToken.WriteTo(WebUrl);
                WebUrl := DelChr(WebUrl, '=', '"');
                exit(WebUrl);
            end else
                Error('Error');
        end;
    end;

}