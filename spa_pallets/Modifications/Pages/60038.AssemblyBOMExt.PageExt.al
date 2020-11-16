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
            field("Fixed Value"; "Fixed Value")
            {
                ApplicationArea = All;
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