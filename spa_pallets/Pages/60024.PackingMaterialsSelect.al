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
                    PackingTrackingLine.setrange("Line No.", "Pallet Packing Line No.");
                    PackingTrackingLine.setrange("Pallet ID", "Pallet ID");
                    if PackingTrackingLine.findfirst then begin
                        PackingTrackingLine.Returned := true;
                        PackingTrackingLine.modify;
                    end;
                until rec.Next = 0;
        end;
    end;
}