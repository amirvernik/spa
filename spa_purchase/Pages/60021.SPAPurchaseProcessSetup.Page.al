page 60021 "SPA Purchase Process Setup"
{

    PageType = Card;
    SourceTable = "SPA Purchase Process Setup";
    Caption = 'SPA Purchase Process Setup';
    UsageCategory = Administration;
    ApplicationArea = all;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Item Journal Batch"; "Item Journal Batch")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CLEAR(LookupBatch);
                        LookupBatch.LOOKUPMODE := TRUE;
                        LookupBatches.reset;
                        LookupBatches.setrange("Journal Template Name", 'ITEM');
                        LookupBatch.SETRECORD(LookupBatches);

                        LookupBatch.SETTABLEVIEW(LookupBatches);

                        IF LookupBatch.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            LookupBatch.GETRECORD(LookupBatches);
                            rec."Item Journal Batch" := LookupBatches.Name;
                            rec.modify;
                        END;
                    end;
                }
                field("Batch No. Series"; "Batch No. Series")
                {
                    ApplicationArea = all;
                }

            }


        }
    }

    trigger OnOpenPage()
    begin
        RESET;
        IF NOT GET THEN BEGIN
            INIT;
            INSERT;
        END;
    end;

    var
        LookupBatch: page "Item Journal Batches";
        LookupBatches: Record "Item Journal Batch";

}
