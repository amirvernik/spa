codeunit 60039 "Item Management"
{
    /*[EventSubscriber(ObjectType::table, database::Item, 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertItem(var Rec: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.reset;
        ItemUnitOfMeasure.SetRange(code, rec."Base Unit of Measure");
        ItemUnitOfMeasure.setrange("Item No.", rec."No.");
        if ItemUnitOfMeasure.FindFirst() then begin
            ItemUnitOfMeasure."Default Unit Of Measure" := true;
            ItemUnitOfMeasure.Modify;
        end;
    end;*/

}