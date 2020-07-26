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
        field(10; "Dispatch Type Code"; code[20])
        {
            Caption = 'Dispatch Type Code';
            DataClassification = ToBeClassified;
            TableRelation = "Format Type".code;
        }
        field(11; "Item Label Type Code"; code[20])
        {
            Caption = 'Item Label Type Code';
            DataClassification = ToBeClassified;
            TableRelation = "Format Type".code;
        }
        field(12; "SSCC Label No. of Copies"; Integer)
        {
            Caption = 'SSCC Label No. of Copies';
            DataClassification = ToBeClassified;
        }
        field(13; "Pallet Label No. of Copies"; Integer)
        {
            Caption = 'Pallet Label No. of Copies';
            DataClassification = ToBeClassified;
        }
        field(15; "Sticker Root Directory"; Text[1024])
        {
            Caption = 'Sticker root Directory';
            DataClassification = ToBeClassified;
        }
        field(20; "Company Prefix"; Text[20])
        {
            Caption = 'Company Prefix';
            DataClassification = ToBeClassified;
        }
        field(21; "SSCC No. Series"; Text[20])
        {
            Caption = 'SSCC No. Series';
            TableRelation = "No. Series";
            DataClassification = ToBeClassified;
        }
        field(30; "Sticker API URI"; text[1024])
        {
            caption = 'Sticker API URI';
            DataClassification = ToBeClassified;
        }
        field(40; "Pallet Label Type Code"; code[20])
        {
            Caption = 'Pallet Label Type Code';
            DataClassification = ToBeClassified;
            TableRelation = "Format Type".code;
        }
        field(41; "SSCC Label Type Code"; code[20])
        {
            Caption = 'SSCC Label Type Code';
            DataClassification = ToBeClassified;
            TableRelation = "Format Type".code;
        }
        field(50; "OneDrive Directory ID"; text[1024])
        {
            Caption = 'OneDrive Directory ID';
            DataClassification = ToBeClassified;
        }
        field(60; "OneDrive Client ID"; text[1024])
        {
            Caption = 'OneDrive Client ID';
            DataClassification = ToBeClassified;
        }
        field(70; "OneDrive Client Secret"; text[1024])
        {
            Caption = 'OneDrive Client Secret';
            DataClassification = ToBeClassified;
        }
        field(80; "OneDrive Drive ID"; text[1024])
        {
            Caption = 'OneDrive Drive ID';
            DataClassification = ToBeClassified;
        }
        field(90; "OneDrive Root Directory"; Text[50])
        {
            Caption = 'OneDrive root Directory';
            DataClassification = ToBeClassified;
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
