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
        responseText: Text;
    begin
        PalletProcessSetup.get;
        //lDirectory := '394ca742-61cd-41ec-b3c2-2b828ef9dcd6';// PalletProcessSetup."OneDrive Directory ID";
        lDirectory := PalletProcessSetup."OneDrive Directory ID";
        lSecret := palletProcessSetup."OneDrive Client Secret";
        lClientID := PalletProcessSetup."OneDrive Client ID";
        lUrl := 'https://login.microsoftonline.com/' + lDirectory + '/oauth2/v2.0/token';
        //lClientID := '3321b880-99b3-4c0f-b9b8-9ba5e6e1a767';//PalletProcessSetup."OneDrive Client ID";
        //lSecret := '6nDgAy.qn.90cH.3BiGyC~3hHpduLST1M1';//PalletProcessSetup."OneDrive Client Secret";
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
            lResponse.Content.ReadAs(responseText);
            Exit(APITokenLocal);
        end
        else
            error('API Token Request failed');
    end;


    Procedure UploadFile(DirectoryPath: text; FileName: Text; BearerToken: Text; pInstr: InStream): Text
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
        lOneDrive: Text;

    begin
        PalletProcessSetup.get;
        lOneDrive := PalletProcessSetup."OneDrive Drive ID";
        //lUrl := 'https://graph.microsoft.com/v1.0/drives/' + 'b!bU7-uco0aUOfOS6tDaxnOmiiplOkFSBGoBfqcq18K0aSue4scQHFQZM5CLGlSEGW' + '/root:/BC/' + FileName + ':/content';
        //lUrl := 'https://graph.microsoft.com/v1.0/drives/' + lOneDrive + '/root:/BC/' + FileName + ':/content';
        lUrl := 'https://graph.microsoft.com/v1.0/drives/' + lOneDrive + '/root:/' + DirectoryPath + '/' + FileName + ':/content';
        Bearer := 'Bearer ' + BearerToken;
        lHeaders.Clear();
        lContent.GetHeaders(lHeaders);
        lHeaders.Remove('Content-Type');
        lHeaders.Add('Content-Type', 'text/plain');
        lreqHeaders := lClient.DefaultRequestHeaders();
        lreqHeaders.Add('Authorization', Bearer);
        lContent.WriteFrom(pInstr);
        lRequest.Content := lContent;
        lRequest.GetHeaders(lReqHeaders);
        lContent.GetHeaders(lHeaders);
        lRequest.Method := 'PUT';
        lRequest.SetRequestUri(lUrl);
        lRequest.GetHeaders(lReqHeaders);
        if lClient.Send(lRequest, lResponse) then begin
            lResponse.Content().ReadAs(BaseTxt);
            //  message(BaseTxt);
            lJsonObj.ReadFrom(BaseTxt);
            if lResponse.IsSuccessStatusCode() then begin
                lJsonObj.Get('createdDateTime', lJsonToken);
                lJsonToken.WriteTo(WebUrl);
                WebUrl := DelChr(WebUrl, '=', '"');
                exit(WebUrl);
            end else
                Error('Error');
        end;
    end;

}