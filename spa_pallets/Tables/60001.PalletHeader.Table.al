table 60001 "Pallet Header"
{
    Caption = 'Pallet Header';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; Code[20])
        {
            Caption = 'Pallet ID';
            DataClassification = ToBeClassified;
        }
        field(2; "Pallet Description"; Text[50])
        {
            Caption = 'Pallet Description';
            DataClassification = ToBeClassified;
        }
        field(3; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
            TableRelation = Location.Code WHERE("Use As In-Transit" = CONST(false));
            trigger onvalidate()
            begin
                if ((Rec."Location Code" <> xrec."Location Code") and (xrec."Location Code" <> '')) then begin
                    PalletLines.reset;
                    palletlines.setrange("Pallet ID", rec."Pallet ID");
                    if PalletLines.findset() then
                        error(Err002);
                end;
            end;
        }
        field(4; "Pallet Status"; Enum "Pallet Status")
        {
            Caption = 'Pallet Status';
            DataClassification = ToBeClassified;
            trigger OnValidate();
            var
            //  PalletFunctionsCU: Codeunit "Pallet Functions";
            begin
                /*if ((Rec."Pallet Status" <> xRec."Pallet Status") and (Rec."Pallet Status" = Rec."Pallet Status"::Consumed))
                 then
                    PalletFunctionsCU.CreateNegAdjustmentToPackingMaterials(Rec);*/
            end;

        }
        field(5; "Creation Date"; date)
        {
            Caption = 'Creation Date';
            DataClassification = ToBeClassified;
        }
        field(6; "User Created"; code[50])
        {
            Caption = 'User Created';
            DataClassification = ToBeClassified;
        }
        field(7; "Exist in warehouse shipment"; Boolean)
        {
            Caption = 'Exist in warehouse shipment';
            DataClassification = ToBeClassified;
        }

        field(8; "Total Qty"; Decimal)
        {
            Caption = 'Total Quantity';
            FieldClass = FlowField;
            CalcFormula = Sum("Pallet Line".Quantity WHERE("Pallet ID" = FIELD("Pallet ID")));
        }
        field(9; "Raw Material Pallet"; Boolean)
        {
            Caption = 'Raw Material Pallet';
            DataClassification = ToBeClassified;
        }
        field(10; "Pallet Type"; Text[20])
        {
            Caption = 'Pallet Type';
            DataClassification = ToBeClassified;
        }
        field(20; "Disposal Status"; Enum "Pallet Disposal approval Status")
        {
            Caption = 'Disposal Status';
            DataClassification = ToBeClassified;
        }
        field(30; "Warehouse Shipment No."; Code[20])
        {
            Caption = 'Warehouse Shipment No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Warehouse Pallet"."Whse Shipment No." where("Pallet ID" = field("Pallet ID")));
            Editable = false;
        }
        field(40; Attention; Boolean)
        {
            Caption = 'Attention';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Pallet ID")
        {
            Clustered = true;
        }
    }
    var

        PalletID: code[20];
        NoSeriesMgt: Codeunit NoSeriesManagement;
        PalletSetup: record "Pallet Process Setup";
        Err001: label 'Pallet Process Setup does not Exist, Please contact system admin';
        Err002: label 'There are Lines, cant change location';
        PalletLines: Record "Pallet Line";
        PalletReservations: Record "Pallet reservation Entry";
        Err003: label 'Pallet is closed, for Delete Please Re-Open';
        Err004: Label 'Pallet is Consumed for Microwave Order, Cannot be Deleted';
        Err005: Label 'Only open Pallets Can Be deleted';
        Err10: Label 'Canceled status is allowed only for open status pallet';

    trigger OnInsert()
    begin

        if PalletSetup.Get() then begin
            IF "Pallet ID" = '' THEN BEGIN
                "Pallet ID" := NoSeriesMgt.GetNextNo(PalletSetup."Pallet No. Series", today, true);
            end;
            "Creation Date" := today;
            "User Created" := UserId;
        END
        else
            error(err001);
    end;

    trigger OnDelete()
    begin
        if rec."Pallet Status" = rec."Pallet Status"::Closed then
            error(Err003);
        if rec."Pallet Status" = rec."Pallet Status"::Consumed then
            error(Err004);

        if rec."Pallet Status" <> rec."Pallet Status"::Open then
            error(Err005);

        PalletReservations.reset;
        PalletReservations.setrange("Pallet ID", rec."Pallet ID");
        if PalletReservations.findset then
            PalletReservations.deleteall;

        PalletLines.reset;
        PalletLines.setrange(PalletLines."Pallet ID", rec."Pallet ID");
        if PalletLines.findset then
            palletlines.deleteall;
    end;

}
