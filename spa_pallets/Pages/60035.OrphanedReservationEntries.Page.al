page 60035 "Orphaned Reservation Entries"
{

    ApplicationArea = All;
    Caption = 'Orphaned Reservation Entries';
    InsertAllowed = false;
    ModifyAllowed = false;
    Editable = true;
    PageType = List;
    SourceTable = "Reservation Entry";
    SourceTableView = SORTING("Entry No.", Positive) ORDER(Ascending) WHERE("Source Type" = CONST(39), "Source Subtype" = CONST(1));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {

                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Source ID"; "Source ID")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        if PurchaseHeader.get("Source Subtype", "Source ID") then
                            page.run(page::"Purchase Order", PurchaseHeader);
                    end;
                }
                field("Source Ref. No."; "Source Ref. No.")
                {
                    ApplicationArea = All;
                }

                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = All;
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = All;
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = All;
                }
                field(QtyReceived; QtyReceived)
                {
                    Caption = 'Qty. Received';
                    ApplicationArea = all;
                }
            }
        }
    }


    trigger OnAfterGetRecord()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.reset;
        PurchaseLine.setrange("Document Type", "Source Subtype");
        PurchaseLine.setrange("Document No.", "Source ID");
        PurchaseLine.setrange("Line No.", "Source Ref. No.");
        if PurchaseLine.findfirst then
            QtyReceived := PurchaseLine."Qty. Received (Base)";
    end;

    trigger OnDeleteRecord(): Boolean
    var
    begin
        if QtyReceived = 0 then
            error('You cannot delete reservation, Purhcase needs to be completed');
    end;

    var

        QtyReceived: Decimal;
}
