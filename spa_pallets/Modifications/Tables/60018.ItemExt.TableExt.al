tableextension 60018 ItemExt extends Item
{
    fields
    {
        field(60018; "MaxQtyPerPallet"; Decimal)
        {
            Caption = 'Max Qty Per Pallet';
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}