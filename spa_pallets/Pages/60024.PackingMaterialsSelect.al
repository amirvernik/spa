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
}