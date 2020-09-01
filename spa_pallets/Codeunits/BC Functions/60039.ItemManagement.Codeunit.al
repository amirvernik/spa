codeunit 60039 "Item Management"
{
    [EventSubscriber(ObjectType::table, database::Item, 'OnAfterValidateEvent', 'No.', true, true)]
    local procedure OnAfterInsertItem(var Rec: Record Item; var xRec: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if ((xrec."No." <> rec."No.") and (xrec."No." = '')) then begin
            ItemUnitOfMeasure.reset;
            ItemUnitOfMeasure.SetRange(code, rec."Base Unit of Measure");
            ItemUnitOfMeasure.setrange("Item No.", rec."No.");
            if ItemUnitOfMeasure.FindFirst() then begin
                ItemUnitOfMeasure."Default Unit Of Measure" := true;
                ItemUnitOfMeasure.Modify;
            end;
        end;
    end;
}