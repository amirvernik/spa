table 60008 "SPA Purchase Process Setup"
{
    Caption = 'SPA Purchase Process Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "Batch No. Series"; Code[20])
        {
            Caption = 'Purchase Batch No. Series';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(3; "Item Journal Batch"; code[10])
        {
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
