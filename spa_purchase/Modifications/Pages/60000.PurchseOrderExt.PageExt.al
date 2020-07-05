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
            }
            field("Harvest Date"; "Harvest Date")
            {
                ApplicationArea = all;
                Editable = PO_Released;
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
            field("Scrap QTY (KG)"; "Scrap QTY (KG)")
            {
                ApplicationArea = all;
                Visible = ScrapVisible;
            }
        }
        addlast(content)
        {
            group("Raw Material")

            {
                //Removed By Oren Ask - TFS98096 - Visible false
                //Visible = po_microwave_process;
                Visible = false;
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
                //Removed By Oren Ask - TFS98096 - Visible false
                //Visible = po_microwave_process;
                Visible = false;

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
        if rec.Status = rec.status::Released then
            PO_Released := false
        else
            PO_Released := true;

        if rec."Microwave Process PO" then
            ScrapVisible := true
        else
            ScrapVisible := false;

    end;

    trigger OnOpenPage()
    begin
        if rec.Status = rec.status::Released then
            PO_Released := false
        else
            PO_Released := true;

        if rec."Microwave Process PO" then
            ScrapVisible := true
        else
            ScrapVisible := false;
    end;

    var
        PO_Released: Boolean;
        RecGPurchaseHeader: Record "Purchase Header";
        ScrapVisible: Boolean;
}