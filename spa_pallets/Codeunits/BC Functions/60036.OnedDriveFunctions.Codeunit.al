codeunit 60036 "OneDrive Functions"
{
    procedure GetBearerToken(): Text
    var
        //Directory ID - 394ca742-61cd-41ec-b3c2-2b828ef9dcd6
        //Client ID - Prodware1@sweetpotatoesaustralia.com.au    
        //client Secret - Cos99362
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
    begin
        lDirectory := '394ca742-61cd-41ec-b3c2-2b828ef9dcd6'; //SPA
        
        lUrl := 'https://login.microsoftonline.com/' + lDirectory + '/oauth2/v2.0/token';
        //lClientID := Onedrivesetup."Client ID";
        //lSecret := OnedriveSetup."Client Secret";
        lClientID := 'avernik@prodware.co.il';
        lSecret := 'Cos99362';
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
            message(format(Token));
            lJsonObj.ReadFrom(Token);
            lJsonObj.Get('access_token', lJsonToken);
            lJsonToken.WriteTo(APITokenLocal);
            APITokenLocal := DelChr(APITokenLocal, '=', '"');
            Exit(APITokenLocal);
        end
        else
            error('API Token Request failed');
    end;
}