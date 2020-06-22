page 60028 "Pallet Consume Select"
{

    PageType = StandardDialog;
    SourceTable = "Pallet Consume Line";
    Caption = 'Select Consumeables';
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            label(LblMessage)

            {
                Style = Strong;
                Caption = 'Please choose quantities to consume on Raw Materials';

            }
            repeater(General)
            {
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Remaining Qty"; "Remaining Qty")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Consumed Qty"; "Consumed Qty")
                {
                    ApplicationArea = all;
                    editable = true;
                }

            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PackingTrackingLine: Record "Packing Material Line";
    begin
        /*if CloseAction = action::OK then begin
            rec.reset;
            rec.setrange(Select, true);
            if rec.findset then
                repeat
                    PackingTrackingLine.reset;
                    //PackingTrackingLine.setrange("Line No.", "Pallet Packing Line No.");
                    PackingTrackingLine.setrange("Item No.", "PM Item No.");
                    PackingTrackingLine.setrange("Pallet ID", "Pallet ID");
                    PackingTrackingLine.setrange("Unit of Measure Code", "Unit of Measure");
                    if PackingTrackingLine.findfirst then begin
                        PackingTrackingLine.Returned := true;
                        PackingTrackingLine."Qty to Return" := rec.Quantity;
                        PackingTrackingLine.modify;
                    end;
                until rec.Next = 0;
        end;*/
    end;
}