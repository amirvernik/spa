tableextension 60018 ItemExt extends Item
{
    fields
    {
        field(60018; "Max Qty Per Pallet"; Decimal)
        {
            Caption = 'Max Qty Per Pallet';
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}