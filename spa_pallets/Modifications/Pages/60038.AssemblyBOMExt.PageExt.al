pageextension 60038 AssemblyBOMExt extends "Assembly BOM"
{
    layout
    {
        addafter("Description")
        {
            field("Reusable item"; "Reusable item")
            {
                Editable = true;
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}