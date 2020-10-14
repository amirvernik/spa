
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
        LPostedWarhousePallet: Record "Posted Warehouse Pallet";
        LPalletLine: Record "Pallet Line";
        LItemAttribute: Record "Item Attribute";
        LItemAttributeValue: Record "Item Attribute Value";
        LItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        LSizeItemAttributeID: Integer;
        LGradeItemAttributeID: Integer;
        LSizeItemAttributeValue: Text;
        LGradeItemAttributeValue: Text;
        LRecPurchaseItemsStatistic: Record "Purchase Items Statistic";
        LTotal: Decimal;
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
        if LPurchaseLine.FindSet() then begin
            LItemAttribute.Reset();
            LItemAttribute.SetRange(Name, 'Size');
            LItemAttribute.FindFirst();
            LSizeItemAttributeID := LItemAttribute.ID;
            LItemAttribute.SetRange(Name, 'Grade');
            LItemAttribute.FindFirst();
            LGradeItemAttributeID := LItemAttribute.ID;
            repeat
                LPalletLine.Reset();
                LPalletLine.SetCurrentKey("Purchase Order No.", "Purchase Order Line No.");
                LPalletLine.SetRange("Purchase Order No.", LPurchaseLine."Document No.");
                LPalletLine.SetRange("Purchase Order Line No.", LPurchaseLine."Line No.");
                if LPalletLine.FindSet() then
                    repeat
                        LPostedWarhousePallet.Reset();
                        LPostedWarhousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                        LPostedWarhousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                        if LPostedWarhousePallet.FindSet() then begin
                            LPostedWarhousePallet.CalcSums(Quantity);
                            LSizeItemAttributeValue := '';
                            LGradeItemAttributeValue := '';
                            if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LSizeItemAttributeID) then begin
                                if LItemAttributeValue.Get(LSizeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID") then
                                    LSizeItemAttributeValue := LItemAttributeValue.Value;
                            end;

                            if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LGradeItemAttributeID) then begin
                                LItemAttributeValue.Get(LGradeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID");
                                LGradeItemAttributeValue := LItemAttributeValue.Value;
                            end;

                            IF not Rec.Get(LGradeItemAttributeValue, LSizeItemAttributeValue, PONumber, UserId) then begin
                                Rec.Init();
                                Rec."User" := UserId;
                                if PONumber <> '' then
                                    Rec."Purchase Number" := PONumber;
                                Rec.Grade := LGradeItemAttributeValue;
                                Rec.Size := LSizeItemAttributeValue;
                                Rec.TotalSize := LPostedWarhousePallet.Quantity;
                                if not Rec.Insert() then Rec.Modify();
                            end else begin
                                Rec.TotalSize += LPostedWarhousePallet.Quantity;
                                Rec.Modify();
                            end;
                        end;
                    until LPalletLine.Next() = 0;
            until LPurchaseLine.Next() = 0;
            Commit();

            Rec.Reset();
            Rec.SetRange(User, UserId);
            if PONumber <> '' then
                Rec.SetRange("Purchase Number", PONumber);
            if Rec.FindSet() then
                repeat
                    LRecPurchaseItemsStatistic.Reset();
                    LRecPurchaseItemsStatistic.SetRange(User, UserId);
                    LRecPurchaseItemsStatistic.SetRange(Grade, Rec.Grade);
                    IF PONumber <> '' then
                        LRecPurchaseItemsStatistic.SetRange("Purchase Number", PONumber);
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