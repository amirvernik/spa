table 60002 "Pallet Process Setup"
{
    Caption = 'Pallet Process Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "Pallet No. Series"; Code[20])
        {
            Caption = 'Pallet No. Series';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(3; "Item Journal Batch"; Code[20])
        {
            Caption = 'Item Journal Batch';
            DataClassification = ToBeClassified;
        }
        field(4; "Item Reclass Batch"; Code[20])
        {
            Caption = 'Item Reclass Batch';
            DataClassification = ToBeClassified;
        }
        Field(5; "Json Text Sample"; Text[2048])
        {
            Caption = 'Json Text Sample';
            DataClassification = ToBeClassified;
        }
        field(6; "Item Reclass Template"; code[20])
        {
            caption = 'Item Reclass Template';
            DataClassification = ToBeClassified;
        }
        field(7; "Cancel Reason Code"; code[20])
        {
            caption = 'Cancel Reason Code';
            DataClassification = ToBeClassified;
            TableRelation = "Reason Code";
        }
        field(8; "Disposal Batch"; code[20])
        {
            caption = 'Disposal Batch';
            DataClassification = ToBeClassified;

        }
        field(9; "Password Pallet Management"; Text[10])
        {
            Caption = 'Password Pallet Management';
            DataClassification = ToBeClassified;
            ExtendedDatatype = Masked;
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

}
