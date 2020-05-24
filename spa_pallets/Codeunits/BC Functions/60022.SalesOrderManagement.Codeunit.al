codeunit 60022 "Sales Orders Management"
{
    //On Before Post Sales Document
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', true, true)]
    local procedure OnBeforePostSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesDocPostMessage: Label 'Will you like to use the delivery date as the invoice date?';
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::order then
            if SalesHeader.Invoice then begin
                if Confirm(SalesDocPostMessage) then begin
                    salesheader."Document Date" := SalesHeader."Requested Delivery Date";
                    SalesHeader.modify;
                end
                else begin
                    salesheader."Document Date" := SalesHeader."Dispatch Date";
                    SalesHeader.modify;
                end;
            end;
    end;

    //On After Validate Customer
    [EventSubscriber(ObjectType::table, database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', true, true)]
    local procedure OnAfterValidateSellToCustomerNo(var Rec: Record "Sales Header")
    var
        CustomerRec: Record Customer;
    begin
        if CustomerRec.get(rec."Sell-to Customer No.") then
            rec."Shipping Time" := CustomerRec."Shipping Time";
    end;

    //On After Change Ship-to Address
    [EventSubscriber(ObjectType::table, database::"sales header", 'OnAfterValidateEvent', 'Ship-to Code', true, true)]
    local procedure OnAfterUpdateSalesShiptoAddress(var Rec: Record "Sales Header")
    var
        ShipToAddress: Record "Ship-to Address";
        CustomerRec: Record Customer;
    begin
        if rec."Ship-to Code" <> '' then begin
            if ShipToAddress.get(rec."Ship-to Code") then begin
                rec."Shipping Time" := ShipToAddress."Shipping Time";
                rec.modify;
            end;
        end
        else begin
            if CustomerRec.get(rec."Sell-to Customer No.") then begin
                rec."Shipping Time" := CustomerRec."Shipping Time";
                rec.modify;

            end;
        end;
    end;

    //On Before Insert Sales Header Record
    [EventSubscriber(ObjectType::table, database::"Sales Header", 'OnBeforeInsertEvent', '', true, true)]
    local procedure OnAfterInsertSalesOrder(var Rec: Record "Sales Header")
    begin
        if rec."Document Type" = rec."Document Type"::Order
        then begin
            rec."User Created" := UserId;
        end;
    end;

    //On Before Release Sales Order
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReleaseSalesDoc', '', true, true)]
    local procedure OnBeforeReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        ErrorReqDelDate: Label 'Req. Delivery Date is mandatory';
    begin
        if SalesHeader."Requested Delivery Date" = 0D then
            Error(ErrorReqDelDate);
    end;

    //On After Release Sales Order
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', true, true)]
    local procedure OnAfterReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLineWOLocation: Label 'Not all lines have locations, please update lines';
        LocationTemp: Record Location temporary;
    begin
        //Change Req. Delivery Date
        salesheader."Dispatch Date" := calcdate('-' + format(salesHeader."Shipping Time"), Today);
        //SalesHeader.modify;

        SalesLine.reset;
        SalesLine.setrange("Document Type", SalesHeader."Document Type");
        SalesLine.Setrange("Document No.", SalesHeader."No.");
        if SalesLine.findset then
            repeat
                SalesLine."Dispatch Date" := SalesHeader."Dispatch Date";
                SalesLine.modify;
            until SalesLine.next = 0;

        //Calculate SPA location New field
        LocationTemp.reset;
        if LocationTemp.findset then
            LocationTemp.deleteall;

        //Check if there are lines without locations
        SalesLine.reset;
        SalesLine.setrange("Document Type", SalesHeader."Document Type");
        SalesLine.Setrange("Document No.", SalesHeader."No.");
        SalesLine.setrange("Location Code", '');
        if SalesLine.findfirst then
            error(SalesLineWOLocation);

        SalesLine.reset;
        SalesLine.setrange("Document Type", SalesHeader."Document Type");
        SalesLine.Setrange("Document No.", SalesHeader."No.");
        if SalesLine.findset then
            repeat
                if not LocationTemp.get(SalesLine."Location Code") then begin
                    LocationTemp.init;
                    LocationTemp.Code := SalesLine."Location Code";
                    LocationTemp.insert;
                end;
            until SalesLine.next = 0;

        LocationTemp.reset;
        if LocationTemp.findset then begin
            if LocationTemp.Count = 1 then
                SalesHeader."SPA Location" := LocationTemp.Code
            else
                SalesHeader."SPA Location" := 'MIX';
        end;
        SalesHeader.modify;
    end;

    //On After Reopen Sales Order
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReopenSalesDoc', '', true, true)]
    local procedure MyProcOnAfterReopenSalesDocumentedure(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."SPA Location" := '';
        SalesHeader."Dispatch Date" := 0D;
        SalesHeader.modify;
    end;


}