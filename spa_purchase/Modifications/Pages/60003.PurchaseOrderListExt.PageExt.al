pageextension 60003 PurchaseOrderListExt extends "Purchase Order List"
{
    layout
    {
        addafter("Buy-from Vendor Name")
        {
            field("Grading Result PO"; "Grading Result PO")
            {
                Caption = 'Grading Result';
                ApplicationArea = all;
            }
            field("Microwave Process PO"; "Microwave Process PO")
            {
                Caption = 'Value Add PO';
                ApplicationArea = all;
            }
            field("Batch Number"; "Batch Number")
            {
                ApplicationArea = all;
            }
            field(Comp_Received; Comp_Received)
            {
                Caption = ' Completely Received';
                ApplicationArea = all;
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
                visible = PO_Microwave_Process;

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

    trigger OnOpenPage()
    begin
        PO_Microwave_Process := true;
        if not rec."Microwave Process PO" then
            PO_Microwave_Process := false
    end;

    trigger OnAfterGetRecord()
    begin
        PO_Microwave_Process := true;
        if not rec."Microwave Process PO" then
            PO_Microwave_Process := false;
        rec.CalcFields("Completely Received");
        if rec."Completely Received" then
            Comp_Received := true else
            Comp_Received := false;
    end;

    var
        PO_Microwave_Process: boolean;
        RecGPurchaseHeader: Record "Purchase Header";
        Comp_Received: Boolean;
}