codeunit 60024 "Change Quality Management"
{
    [EventSubscriber(ObjectType::table, database::"Pallet Change Quality", 'OnAfterValidateEvent', 'New Variant Code', true, true)]
    local procedure OnAfterValidateItemVariant(var Rec: Record "Pallet Change Quality")
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Reset();
        ItemVariant.setrange(code, rec."New Variant Code");
        ItemVariant.setrange("Item No.", rec."New Item No.");
        if ItemVariant.findfirst then begin
            Rec.Description := ItemVariant.Description;
            rec.modify;
        end;
    end;
}