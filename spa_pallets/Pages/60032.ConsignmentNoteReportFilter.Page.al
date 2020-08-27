page 60032 "Consignment Note Filetr"
{
    PageType = StandardDialog;
    // PageType = Card;
    Editable = true;
    ApplicationArea = All;
    UsageCategory = Administration;
    // SourceTable = TableName;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("From Date"; FromDate)

                {
                    ApplicationArea = All;
                    NotBlank = true;
                    // trigger OnValidate()
                    // var
                    // begin
                    //     // if (FromDate = 0D) then
                    //     //     error('תאריך');
                    // end;
                }

                field("To Date"; ToDate)
                {
                    ApplicationArea = ALL;
                }

                field("Customer number"; CustomerNum)
                {
                    ApplicationArea = ALL;
                    TableRelation = Customer;

                }
                field("Sales Order Number"; NumOrder)
                {
                    ApplicationArea = ALL;
                    Lookup = true;
                    TableRelation = "Sales Header"."No." where("Document Type" = filter('Order'));
                    Editable = true;

                    trigger OnLookup(VAR Text: Text): Boolean
                    var
                        SalesHedwer: Record "Sales Header";
                        SalesHedwerS: page "Sales Order List";
                    begin
                        SalesHedwer.Reset();
                        IF CustomerNum <> '' THEN
                            SalesHedwer.SetRange("Sell-to Customer No.", CustomerNum);
                        IF FromDate > 0D THEN
                            SalesHedwer.SetFilter("Dispatch Date", '>=%1', FromDate);
                        IF ToDate > 0D THEN
                            SalesHedwer.SetFilter("Dispatch Date", '<=%1', ToDate);
                        IF (FromDate > 0D) AND (ToDate > 0D) THEN
                            SalesHedwer.SetRange("Dispatch Date", FromDate, ToDate);


                        CLEAR(SalesHedwerS);
                        SalesHedwerS.SETRECORD(SalesHedwer);
                        SalesHedwerS.SETTABLEVIEW(SalesHedwer);
                        SalesHedwerS.LOOKUPMODE(TRUE);
                        IF SalesHedwerS.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            SalesHedwerS.GETRECORD(SalesHedwer);
                            Text := SalesHedwer."No.";
                            NumOrder := SalesHedwer."No.";
                        END ELSE BEGIN
                            Text := 'RESOURCE NOT FOUND';
                        END;
                    end;

                    // CLEAR(myTabfrm);
                    // myRec.RESET();
                    // myTabfrm.SETTABLEVIEW(myRec) ;
                    // myTabfrm.LOOKUPMODE(TRUE) ;
                    // IF myTabfrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    // myTabfrm.GETRECORD(myRec);
                    // SETFILTER(text,myRec.text);
                    // END;
                }
            }


        }



    }

    /*actions
    {
        area(Processing)
        {
            action("aaaa")
            {
                ApplicationArea = All;
                Caption = 'My New Action';


                trigger OnAction()
                var
                    ConsignmentReport: Report ConsignmentNote;
                    SalesHeader: Record "Sales Header";
                begin
                    if NumOrder = '' then
                        error('אין הזמנה')
                    else begin
                        SalesHeader.Reset();
                        SalesHeader.SetRange("No.", NumOrder);
                        if SalesHeader.FindFirst() then begin
                            ConsignmentReport.UpdateReport(SalesHeader);
                            ConsignmentReport.RunModal();
                        end;
                    end;

                end;
            
 
            }
         

}
        // Adding a new action group 'MyNewActionGroup' in the 'Creation' area

    }*/
    trigger OnQueryClosePage(CloseAction: Action): Boolean;

    var
        ConsignmentReport: Report "Consignment Note";
        SalesHeader: Record "Sales Header";
        Lbl001: label 'You need to choose sales order';
    begin

        if CloseAction = Action::OK then begin
            if NumOrder = '' then
                error(Lbl001)
            else begin
                SalesHeader.Reset();
                SalesHeader.SetRange("No.", NumOrder);
                if SalesHeader.FindFirst() then begin
                    ConsignmentReport.UpdateReport(SalesHeader);
                    ConsignmentReport.RunModal();
                end;
            end;
        end

        //your code under OK button

        else
            exit(true); //Close the page

    end;

    var
        FromDate: Date;
        ToDate: Date;
        CustomerNum: Code[20];
        NumOrder: Code[20];
}