page 60032 "Consignment Note Filetr"
{
    PageType = StandardDialog;
    // PageType = Card;
    Editable = true;
    UsageCategory = Administration;
    // SourceTable = TableName;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                /*field("From Date"; FromDate)

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

                }*/
                field("Sales Order Number"; NumOrder)
                {
                    ApplicationArea = ALL;
                    Lookup = true;
                    Editable = true;

                    trigger OnLookup(VAR Text: Text): Boolean
                    var
                        //SalesHedwer: Record "Sales Header";
                        //ArchiveSalesHeader: Record "Sales Header Archive";
                        //SalesHedwerS: page "Sales Order List";
                        LPostedWhShipmentLine: Record "Posted Whse. Shipment Line";
                        LPostedWHShipmentLinePage: page "Posted Whse. Shipment List";
                    begin
                        /*LPostedWhShipmentLine.Reset();
                        LPostedWhShipmentLine.SetCurrentKey("Source No.");
                        SalesHedwer.Reset();
                        IF CustomerNum <> '' THEN
                            SalesHedwer.SetRange("Sell-to Customer No.", CustomerNum);
                        IF (FromDate > 0D) and (ToDate <> 0D) THEN
                            SalesHedwer.SetFilter("Dispatch Date", '>=%1', FromDate);
                        IF (ToDate > 0D) and (FromDate <> 0D) THEN
                            SalesHedwer.SetFilter("Dispatch Date", '<=%1', ToDate);
                        IF (FromDate > 0D) AND (ToDate > 0D) THEN
                            SalesHedwer.SetRange("Dispatch Date", FromDate, ToDate);
                        if SalesHedwer.FindSet() then
                            repeat
                                LPostedWhShipmentLine.SetRange("Source No.", SalesHedwer."No.");
                                if LPostedWhShipmentLine.FindFirst() then
                                    LPostedWhShipmentLine.Mark(true);
                            until SalesHedwer.Next() = 0;

                        ArchiveSalesHeader.Reset();
                        IF CustomerNum <> '' THEN
                            ArchiveSalesHeader.SetRange("Sell-to Customer No.", CustomerNum);
                        IF (FromDate > 0D) and (ToDate <> 0D) THEN
                            ArchiveSalesHeader.SetFilter("Dispatch Date", '>=%1', FromDate);
                        IF (ToDate > 0D) and (FromDate <> 0D) THEN
                            ArchiveSalesHeader.SetFilter("Dispatch Date", '<=%1', ToDate);
                        IF (FromDate > 0D) AND (ToDate > 0D) THEN
                            ArchiveSalesHeader.SetRange("Dispatch Date", FromDate, ToDate);
                        if ArchiveSalesHeader.FindSet() then
                            repeat
                                LPostedWhShipmentLine.SetRange("Source No.", ArchiveSalesHeader."No.");
                                if LPostedWhShipmentLine.FindFirst() then
                                    LPostedWhShipmentLine.Mark(true);
                            until ArchiveSalesHeader.Next() = 0;
*/
                        CLEAR(LPostedWHShipmentLinePage);
                        LPostedWhShipmentLine.Reset();
                        LPostedWHShipmentLinePage.SETRECORD(LPostedWhShipmentLine);
                        LPostedWHShipmentLinePage.SETTABLEVIEW(LPostedWhShipmentLine);
                        LPostedWHShipmentLinePage.LOOKUPMODE(TRUE);
                        IF LPostedWHShipmentLinePage.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            LPostedWHShipmentLinePage.GETRECORD(LPostedWhShipmentLine);
                            Text := LPostedWhShipmentLine."Source No.";
                            NumOrder := LPostedWhShipmentLine."Source No.";
                        END ELSE BEGIN
                            Text := 'RESOURCE NOT FOUND';
                        END;
                    end;

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