tableextension 60000 PurchaseHeaderExt extends "Purchase Header"
{
    fields
    {
        field(60000; "Number Of Raw Material Bins"; Integer)
        {
        }
        field(60001; "Harvest Date"; date)
        {
        }
        field(60002; "Grading Result PO"; Boolean)
        {
        }
        field(60003; "Microwave Process PO"; Boolean)
        {
        }
        field(60004; "Raw Material Item"; code[20])
        {
            TableRelation = item."No.";

        }
        field(60005; "RM Location"; code[20])
        {
            TableRelation = Location.Code;

        }
        field(60006; "RM Qty"; Integer)
        {

        }
        field(60007; "Item LOT Number"; code[20])
        {
            trigger OnLookup()
            begin
                CLEAR(LookupLot);
                LookupLot.LOOKUPMODE := TRUE;
                RecGItemLedgerEntry.setrange("Item No.", rec."Raw Material Item");
                RecGItemLedgerEntry.setrange("Location Code", "RM Location");
                LookupLot.SETRECORD(RecGItemLedgerEntry);
                LookupLot.SETTABLEVIEW(RecGItemLedgerEntry);

                IF LookupLot.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    LookupLot.GETRECORD(RecGItemLedgerEntry);
                    rec."Item LOT Number" := RecGItemLedgerEntry."Lot No.";
                    rec."RM Qty" := RecGItemLedgerEntry.Quantity;
                    rec."Batch Number" := rec."Item LOT Number";
                end;
            END;

        }
        field(60008; "Batch Number"; code[20])
        {

        }
        field(60009; "RM Add Neg"; Boolean)
        {

        }
        field(60010; "Scrap QTY (KG)"; Decimal)
        {

        }

    }

    var
        RecGReservationEntry: Record "Reservation Entry";
        LookupLot: Page "Lot Selection List";
        RecGItemLedgerEntry: Record "Item Ledger Entry";
}