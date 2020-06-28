page 60024 "Packing Materials Select"
{

    PageType = StandardDialog;
    SourceTable = "Packing Materials Select";
    Caption = 'Select PM';
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            label(LblMessage)

            {
                Style = Strong;
                Caption = 'Are there any packing material you would like to return to stock? If so, please choose them and choose Quantities';

            }
            repeater(General)
            {
                field(Select; Select)
                {
                    ApplicationArea = All;
                }

                field("PM Item No."; "PM Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("PM Item Description"; "PM Item Description")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = all;
                    trigger OnValidate()
                    var
                        ErrorQuantity: Label 'You cannot enter bigger quantity than on pallet';
                    begin
                        if rec.Quantity > xRec.Quantity then
                            error(ErrorQuantity);
                    end;
                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PackingTrackingLine: Record "Packing Material Line";
    begin
        if CloseAction = action::OK then begin
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
        end;
    end;
}