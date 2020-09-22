codeunit 60022 "Sales Orders Management"
{
    //On Before Post Sales Document
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', true, true)]
    local procedure OnBeforePostSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesDocPostMessage: Label 'Would you like to use the delivery date as the invoice date?';
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
        if CustomerRec.get(rec."Sell-to Customer No.") then begin
            rec."Shipping Time" := CustomerRec."Shipping Time";
            rec."Packing Days" := CustomerRec."Packing Days";

            rec.Validate("Salesperson Code", CustomerRec."Salesperson Code");
            rec.validate("Shipping Agent Code", CustomerRec."Shipping Agent Code");
            rec.validate("Shipping Agent Service Code", CustomerRec."Shipping Agent Service Code");
        end;

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
            if SalesHeader."Document Type" = salesheader."Document Type"::Order then
                Error(ErrorReqDelDate);
    end;

    //On After Release Sales Order
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', true, true)]
    local procedure OnAfterReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesLineWOLocation: Label 'Not all lines have locations, please update lines';
        LItem: Record Item;
        LocationTemp: Record Location temporary;
        Err001: label 'Customer does not have Packing days, Please update and release again';
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            //Change Req. Delivery Date
            if (format(salesHeader."Shipping Time") <> '') and (SalesHeader."Requested Delivery Date" <> 0D) then
                salesheader."Dispatch Date" := calcdate('-' + format(salesHeader."Shipping Time"), SalesHeader."Requested Delivery Date")
            else
                SalesHeader."Dispatch Date" := SalesHeader."Requested Delivery Date";
            //SalesHeader.modify;

            //Calculate Packing Date
            if Customer.get(SalesHeader."Sell-to Customer No.") then
                if customer."Packing Days" = 0 then
                    SalesHeader."Pack-out Date" := SalesHeader."Requested Delivery Date";
            if SalesHeader."Requested Delivery Date" <> 0D then
                salesheader."Pack-out Date" := calcdate('-' + format(SalesHeader."Packing Days") + 'D', SalesHeader."Requested Delivery Date")
            else
                SalesHeader."Pack-out Date" := 0D;

            //Calculate Dispatch Date
            SalesLine.reset;
            SalesLine.setrange("Document Type", SalesHeader."Document Type");
            SalesLine.Setrange("Document No.", SalesHeader."No.");
            if SalesLine.findset then
                repeat
                    SalesLine."Dispatch Date" := SalesHeader."Dispatch Date";
                    SalesLine.modify;
                until SalesLine.next = 0;

            //The dispatch date cant be before then the pack out date
            if SalesHeader."Dispatch Date" < SalesHeader."Pack-out Date" then
                SalesHeader."Dispatch Date" := SalesHeader."Pack-out Date";

            //Calculate SPA location New field
            LocationTemp.reset;
            if LocationTemp.findset then
                LocationTemp.deleteall;

            //Check if there are lines without locations
            SalesLine.reset;
            SalesLine.setrange("Document Type", SalesHeader."Document Type");
            SalesLine.Setrange("Document No.", SalesHeader."No.");
            SalesLine.setrange("Location Code", '');
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetFilter("No.", '<>%1', '');
            if SalesLine.FindSet() then
                repeat
                    if LItem.Get(SalesLine."No.") then
                        if LItem.Type = LItem.Type::Inventory then
                            error(SalesLineWOLocation);
                until SalesLine.Next() = 0;

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
    end;

    //On After Reopen Sales Order
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReopenSalesDoc', '', true, true)]
    local procedure MyProcOnAfterReopenSalesDocumentedure(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesHeader."SPA Location" := '';
            SalesHeader."Dispatch Date" := 0D;
            SalesHeader."Pack-out Date" := 0D;
            SalesHeader.modify;
        end;
    end;


}