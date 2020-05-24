pageextension 60007 ReturnOrderSubpageExt extends "Sales Return Order Subform"
{
    layout
    {
        addafter(Type)
        {
            field("Pallet/s Exist"; "Pallet/s Exist")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
        modify("No.")
        {
            StyleExpr = StyleExpression;
        }
        modify(Description)
        {
            StyleExpr = StyleExpression;
        }
        modify("Location Code")
        {
            StyleExpr = StyleExpression;
        }
        modify(Quantity)
        {
            StyleExpr = StyleExpression;
        }
        modify("Unit of Measure Code")
        {
            StyleExpr = StyleExpression;
        }
        modify("Unit Price")
        {
            StyleExpr = StyleExpression;
        }
        modify("Line Discount %")
        {
            StyleExpr = StyleExpression;
        }
        modify("Line Amount")
        {
            StyleExpr = StyleExpression;
        }
    }


    actions
    {
        addlast("F&unctions")
        {
            action("Show Pallet/s")
            {

                Image = ImportCodes;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                Visible = BoolShowPallets;

                trigger OnAction()

                begin
                    PalletLedgerEntry.reset;
                    PalletLedgerEntry.SetRange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Sales Shipment");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Order No.", "SPA Order No.");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Order Line No.", "SPA Order Line No.");
                    PalletLedgerEntry.setrange("Order Type", 'Sales Order');
                    if PalletLedgerEntry.findfirst then
                        page.run(page::"Pallet Ledger Entries", PalletLedgerEntry)

                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        BoolShowPallets := false;
        if rec."Pallet/s Exist" then begin
            StyleExpression := 'strongaccent';
            BoolShowPallets := true;
        end
        else begin
            StyleExpression := 'standard';
            BoolShowPallets := false;
        end;
    end;

    var
        StyleExpression: Text;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        BoolShowPallets: Boolean;
}