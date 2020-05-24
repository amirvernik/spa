page 60008 "Pallet Ledger Entries"
{

    PageType = List;
    SourceTable = "Pallet Ledger Entry";
    Caption = 'Pallet Ledger Entries';
    ApplicationArea = All;
    Editable = false;
    UsageCategory = Lists;
    SourceTableView = order(descending);

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = all;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = all;
                }
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = all;
                }
                field("Pallet Line No."; "Pallet Line No.")
                {
                    ApplicationArea = all;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = all;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = all;
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = all;
                }
                field("Lot Number"; "Lot Number")
                {
                    ApplicationArea = all;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = all;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = all;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = all;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = all;
                }
                field("Document Line No."; "Document Line No.")
                {
                    ApplicationArea = all;
                }
                field("Order Type"; "Order Type")
                {
                    ApplicationArea = all;
                }
                field("Sales Order No."; "Order No.")
                {
                    ApplicationArea = all;
                }
                field("Sales Order Line No."; "Order Line No.")
                {
                    ApplicationArea = all;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = all;
                }
                field("Item Ledger Entry No."; "Item Ledger Entry No.")
                {
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    begin
                        ItemLedgerEntry.reset;
                        ItemLedgerEntry.setrange("Entry No.", "Item Ledger Entry No.");
                        if ItemLedgerEntry.findset then
                            page.run(page::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
                field("Date Time Created"; "Date Time Created")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
    var
        ItemLedgerEntry: Record "Item Ledger Entry";

}
