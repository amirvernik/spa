
page 60037 "Purchase Items Statistic"
{
    Caption = 'Grading Statistics';
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Purchase Items Statistic";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater("")
            {
                field(Grade; Grade)
                {
                    ApplicationArea = All;
                }
                field(Size; Size)
                {
                    ApplicationArea = All;
                }
                field(TotalSize; TotalSize)
                {
                    ApplicationArea = All;
                }
                field(TotalGrade; TotalGrade)
                {
                    ApplicationArea = All;
                }
                field(Proportion; Proportion)
                {
                    ApplicationArea = ALL;
                }

            }
        }
    }

    procedure fillIn(PONumber: Code[20]);
    var
        LPurchaseLine: Record "Purchase Line";
        LItemAttribute: Record "Item Attribute";
        LItemAttributeValue: Record "Item Attribute Value";
        LItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        LSizeItemAttributeID: Integer;
        LGradeItemAttributeID: Integer;
        LSizeItemAttributeValue: Text;
        LGradeItemAttributeValue: Text;
        LRecPurchaseItemsStatistic: Record "Purchase Items Statistic";
        LTotal: Decimal;
        LQuantityLine: Decimal;
        LItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        Rec.Reset();
        Rec.SetRange("User", UserId);
        if Rec.FindSet() then Rec.DeleteAll();

        LTotal := 0;
        LPurchaseLine.Reset();
        LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
        if PONumber <> '' then
            LPurchaseLine.SetRange("Document No.", PONumber);
        LPurchaseLine.SetRange(Type, LPurchaseLine.Type::Item);
        LPurchaseLine.SetFilter("Quantity Received", '<>%1', 0);
        LPurchaseLine.SetFilter("Line Discount %", '<>%1', 100);
        if LPurchaseLine.FindSet() then begin
            repeat
                LSizeItemAttributeValue := '';
                LGradeItemAttributeValue := '';
                LQuantityLine := 0;
                if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LSizeItemAttributeID) then begin
                    if LItemAttributeValue.Get(LSizeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID") then
                        LSizeItemAttributeValue := LItemAttributeValue.Value;
                end;

                if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LGradeItemAttributeID) then begin
                    LItemAttributeValue.Get(LGradeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID");
                    LGradeItemAttributeValue := LItemAttributeValue.Value;
                end;
                if LGradeItemAttributeValue <> '' then begin
                    LItemUnitofMeasure.Reset();
                    LItemUnitofMeasure.SetRange("Item No.", LPurchaseLine."No.");
                    LItemUnitofMeasure.SetRange(Code, 'KG');
                    LItemUnitofMeasure.FindFirst();
                    LQuantityLine += LPurchaseLine."Quantity Received" * LItemUnitofMeasure."Qty. per Unit of Measure";

                    IF not Rec.Get(LGradeItemAttributeValue, LSizeItemAttributeValue, LPurchaseLine."Document No.", UserId) then begin
                        Rec.Init();
                        Rec."User" := UserId;
                        Rec."Purchase Number" := LPurchaseLine."Document No.";
                        Rec.Grade := LGradeItemAttributeValue;
                        Rec.Size := LSizeItemAttributeValue;
                        Rec.TotalSize := LQuantityLine;
                        Rec."PO Line Amount" := LPurchaseLine."Unit Cost (LCY)" * LQuantityLine;
                        if not Rec.Insert() then Rec.Modify();
                    end else begin
                        Rec.TotalSize += LQuantityLine;
                        Rec."PO Line Amount" += LPurchaseLine."Unit Cost (LCY)" * LQuantityLine;
                        Rec.Modify();
                    end;
                end;
            until LPurchaseLine.Next() = 0;
            Commit();
            Rec.Reset();
            Rec.SetRange(User, UserId);
            Rec.SetRange("Purchase Number", LPurchaseLine."Document No.");
            if Rec.FindSet() then
                repeat
                    LRecPurchaseItemsStatistic.Reset();
                    LRecPurchaseItemsStatistic.SetRange(User, UserId);
                    LRecPurchaseItemsStatistic.SetRange(Grade, Rec.Grade);
                    LRecPurchaseItemsStatistic.SetRange("Purchase Number", LPurchaseLine."Document No.");
                    if LRecPurchaseItemsStatistic.FindSet() then
                        repeat
                            Rec.TotalGrade += LRecPurchaseItemsStatistic.TotalSize;
                        until LRecPurchaseItemsStatistic.Next() = 0;
                    LTotal += Rec.TotalSize;

                    Rec.Modify();
                until Rec.Next() = 0;


            Rec.Reset();
            Rec.SetRange(User, UserId);
            if PONumber <> '' then
                Rec.SetRange("Purchase Number", PONumber);
            if Rec.FindSet() then
                repeat
                    Rec.Proportion := Rec.TotalSize / LTotal;
                    Rec.Modify();
                until Rec.Next() = 0;
        end;
        Rec.SetRange("User", UserId);
        if PONumber <> '' then
            Rec.SetRange("Purchase Number", PONumber);
        Rec.Ascending;
        CurrPage.Update(false);
    end;

}