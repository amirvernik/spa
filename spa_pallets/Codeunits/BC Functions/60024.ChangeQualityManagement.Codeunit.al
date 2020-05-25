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

    [EventSubscriber(ObjectType::table, database::"Pallet Line Change Quality", 'OnAfterValidateEvent', 'Replaced Qty', true, true)]
    local procedure OnAfterValidateReplacedQty(var Rec: Record "Pallet Line Change Quality")
    var
        ErrReplacedQty: label 'You cannot replace quantity %1 that is bigger than %2';
    begin
        if rec."Replaced Qty" > rec.Quantity then
            error(ErrReplacedQty, format(rec."Replaced Qty"), format(rec.Quantity));
    end;
}