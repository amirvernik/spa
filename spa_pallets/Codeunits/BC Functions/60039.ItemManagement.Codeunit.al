codeunit 60039 "Item Management"
{
    [EventSubscriber(ObjectType::table, database::"Item Template", 'OnAfterInsertItemFromTemplate', '', true, true)]
    local procedure OnAfterInsertItem(var ItemTemplate: Record "Item Template"; ConfigTemplateHeader: Record "Config. Template Header"; var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // if ((xrec."No." <> rec."No.") and (xrec."No." = '')) then begin
        ItemUnitOfMeasure.reset;
        ItemUnitOfMeasure.SetRange(code, Item."Base Unit of Measure");
        ItemUnitOfMeasure.setrange("Item No.", Item."No.");
        if ItemUnitOfMeasure.FindFirst() then begin
            ItemUnitOfMeasure."Default Unit Of Measure" := true;
            ItemUnitOfMeasure.Modify;
        end;
        // end;
    end;
}