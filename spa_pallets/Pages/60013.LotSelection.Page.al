page 60013 "Lot Selection"
{
    PageType = list;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "Lot Selection New";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Lot; lot)
                {
                    ApplicationArea = All;
                    Caption = 'Lot No.';
                    Editable = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    Editable = false;
                }
                field("Variant code"; "Variant code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                    Editable = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expiry Date';
                    Editable = false;
                }
                field("Qty. to Reserve"; "Qty. to Reserve")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Reserve';

                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    Editable = false;

                }
                field("Quantity Available"; "Quantity Available")
                {
                    ApplicationArea = All;
                    Caption = 'Available Quantity';
                    Editable = false;
                }
                field("Purchase Order"; "Purchase Order")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Purchase Order Line"; "Purchase Order Line")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;
                Visible = false;


                trigger OnAction();
                begin

                end;
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        palletLine: Record "Pallet Line";
        Err001: label 'Quantity available is greater than quantity to reserve, please change the quantity';
        Err002: Label 'You cannot change the Reservation Quantity more than Available Quantity';
    begin
        if CloseAction = CloseAction::LookupOK then
            if palletLine.get(rec."Pallet ID", rec."Pallet Line No.") then begin
                /*if rec."Quantity Available" < rec."Qty. to Reserve" then begin
                    error(Err001);
                    exit;
                end;*/

                if rec."Quantity Available" < rec."Qty. to Reserve" then begin
                    error(Err002);
                    exit;
                end;

                palletLine."Expiration Date" := rec."Expiration Date";
                //palletLine.validate(Quantity, rec.Quantity);
                palletLine.validate(Quantity, rec."Qty. to Reserve");
                palletLine.validate("Lot Number", REC.Lot);
                palletLine."Purchase Order No." := Rec."Purchase Order";
                palletLine."Purchase Order Line No." := Rec."Purchase Order Line";
                palletLine.modify;
            end;
        commit;
    end;
}