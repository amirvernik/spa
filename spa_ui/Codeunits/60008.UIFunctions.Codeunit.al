codeunit 60008 UIFunctions
{
    trigger OnRun()
    begin
        WSPublisher(GFunction, Gcontent);
    end;

    procedure SendRequest(VAR pFunction: Text[50]; pContent: Text): Text
    var
        LRequest: text;
        LFunction: text[50];
        LNoTriggerExist: Label 'No such Trigger Exist: ';
        UIFunctions: Codeunit "UIFunctions";

    begin
        //LRequest := pContent;
        LFunction := pFunction;

        UIFunctions.InitMessage(pFunction, pContent);
        IF (UIFunctions.RUN) THEN BEGIN
            LRequest := UIFunctions.GetResult;
            if (LRequest <> pContent) then begin
                pFunction := 'Success';
                EXIT(UIFunctions.GetResult);
            end else begin
                pFunction := 'Error';
                exit(LNoTriggerExist + LFunction);
            end;
        END ELSE BEGIN
            pFunction := 'Error';
            EXIT(GETLASTERRORTEXT);
        END;


    end;

    [BusinessEvent(TRUE)]
    local procedure WSPublisher(VAR pFunction: Text[50]; VAR pContent: Text)
    begin
    end;

    procedure InitMessage(pFunction: Text[50]; pContent: Text)
    var
        myInt: Integer;
    begin
        GFunction := pFunction;
        Gcontent := pContent

    end;

    procedure GetResult(): Text
    var
    begin
        EXIT(Gcontent);
    end;
    //Suscriber for test Purpose
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure FirstSubscriber(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        Customer: Record "Customer";
    begin
        IF pFunction <> 'TrygetCustName' THEN
            EXIT;
        Customer.GET(pContent);
        //Customer.Name := FORMAT(CURRENTDATETIME);
        //Customer.MODIFY;
        pContent := Customer.Name;
    end;



    var
        GFunction: Text[50];
        Gcontent: Text;
}