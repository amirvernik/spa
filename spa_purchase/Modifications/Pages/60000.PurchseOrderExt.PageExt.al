pageextension 60000 PurchaseOrderExt extends "Purchase Order"
{
    layout
    {
        modify("Vendor Shipment No.")
        {
            ShowMandatory = true;
        }
        modify("Purchaser Code")
        {
            ShowMandatory = true;
        }
        addlast(General)
        {
            field("Number Of Raw Material Bins"; "Number Of Raw Material Bins")
            {
                ApplicationArea = all;
                Editable = PO_Released;
                visible = PO_Reg_Fields;
            }
            field("Harvest Date"; "Harvest Date")
            {
                ApplicationArea = all;
                Editable = PO_Released;
                visible = PO_Reg_Fields;
            }
            field("Grading Result PO"; "Grading Result PO")
            {
                ApplicationArea = all;
                Editable = false;

            }
            field("Microwave Process PO"; "Microwave Process PO")
            {
                Caption = 'Value Add PO';
                ApplicationArea = all;
                Editable = false;
            }
            field("Batch Number"; "Batch Number")
            {
                ApplicationArea = all;
                editable = false;
            }
        }
        addlast(content)
        {
            group("Raw Material")

            {
                Visible = po_microwave_process;
                field("Raw Material Item"; "Raw Material Item")
                {
                    ApplicationArea = all;
                }
                field("RM Location"; "RM Location")
                {
                    ApplicationArea = all;
                }
                field("Item LOT Number"; "Item LOT Number")
                {
                    ApplicationArea = all;
                }
                field("RM Qty"; "RM Qty")
                {
                    ApplicationArea = all;
                }

            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("Choose Microwave R.M")
            {
                ApplicationArea = All;
                Image = ItemTracing;
                Visible = po_microwave_process;

                trigger OnAction()
                begin
                    RecGPurchaseHeader.reset;
                    RecGPurchaseHeader.setrange("Document Type", rec."Document Type");
                    RecGPurchaseHeader.setrange("No.", rec."No.");
                    if RecGPurchaseHeader.FindFirst then
                        page.run(page::"Raw Material Select Page", RecGPurchaseHeader);
                end;
            }

        }
    }
    trigger OnAfterGetRecord()
    begin
        PO_Microwave_Process := true;
        PO_Reg_Fields := true;

        if rec.Status = rec.status::Released then
            PO_Released := false
        else
            PO_Released := true;

        if not rec."Microwave Process PO" then
            PO_Microwave_Process := false;

        if rec."Microwave Process PO" then
            PO_Reg_Fields := false;
    end;

    trigger OnOpenPage()
    begin
        PO_Microwave_Process := true;
        PO_Reg_Fields := true;
        if rec.Status = rec.status::Released then
            PO_Released := false
        else
            PO_Released := true;
        if not rec."Microwave Process PO" then
            PO_Microwave_Process := false;
        if rec."Microwave Process PO" then
            PO_Reg_Fields := false;

    end;

    var
        PO_Released: Boolean;
        PO_Microwave_Process: boolean;
        RecGPurchaseHeader: Record "Purchase Header";
        PO_Reg_Fields: Boolean;
}