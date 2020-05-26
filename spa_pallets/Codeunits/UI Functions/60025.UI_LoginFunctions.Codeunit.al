codeunit 60025 "UI Login Functions"
{
    //Get List Of Items by Attributes
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CheckUserValidation(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        UserSetup: Record "User Setup";
        JsonBuffer: Record "JSON Buffer" temporary;
        UserName: Text;
        UserPassword: Text;
        JsonObj: JsonObject;

    begin
        IF pFunction <> 'CheckUserValidation' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);
        JSONBuffer.RESET;

        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN begin
                    IF STRPOS(JSONBuffer.Path, 'user_name') > 0 THEN begin
                        UserName := JSONBuffer.Value;
                    end;
                    IF STRPOS(JSONBuffer.Path, 'user_password') > 0 THEN begin
                        UserPassword := JSONBuffer.Value;
                    end;
                end;
            UNTIL JSONBuffer.NEXT = 0;
        end;

        UserSetup.reset;
        UserSetup.setrange(UserSetup."User ID", UserName);
        if UserSetup.findset then begin
            if UserSetup."UI Password" = UserPassword then begin
                JsonObj.Add('Status', true);
                JsonObj.Add('WsPass', UserSetup."WS Access Key");
                JsonObj.WriteTo(pContent);
            end
            else begin
                JsonObj.Add('Status', false);
                JsonObj.Add('WsPass', 'Wrong Password');
                JsonObj.WriteTo(pContent);
            end;
        end
        else begin
            JsonObj.Add('Status', false);
            JsonObj.Add('WsPass', 'Invalid User');
            JsonObj.WriteTo(pContent);
        end;
    end;

}
 No newline at end of file
