codeunit 60039 "Item Management"
{
    [EventSubscriber(ObjectType::table, database::Item, 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertItem(var Rec: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin

    end;
}