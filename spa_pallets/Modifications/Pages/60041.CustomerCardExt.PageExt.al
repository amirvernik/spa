pageextension 60041 CustomerCardExt extends "Customer Card"
{
    layout
    {
        addafter("Disable Search by Name")
        {
            group("Sticker Note")
            {
                field("Dispatch Format"; "Dispatch Format")
                {
                    Editable = false;
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        PalletProccessSetup: Record "Pallet Process Setup";
                        StickerFormat: Record "Sticker Format";
                        Err001: Label 'Dispatch Format is not Setup, Please contact system admin';
                        StickerFormatPage: page "Sticker Formats";
                    begin
                        PalletProccessSetup.get;
                        if PalletProccessSetup."Dispatch Type Code" <> '' then begin
                            CLEAR(StickerFormatPage);
                            StickerFormatPage.LOOKUPMODE := TRUE;
                            StickerFormat.reset;
                            StickerFormat.setrange("Format Type", PalletProccessSetup."Dispatch Type Code");
                            //if StickerFormat.findset then begin
                            StickerFormatPage.SETRECORD(StickerFormat);
                            StickerFormatPage.SETTABLEVIEW(StickerFormat);
                            IF StickerFormatPage.RUNMODAL = ACTION::LookupOK THEN BEGIN
                                StickerFormatPage.GETRECORD(StickerFormat);
                                rec."Dispatch Format" := StickerFormat."Sticker Description";
                                rec.modify;
                            END;
                            //end;

                        end
                        else
                            error(Err001);
                    end;
                }
                field("Dispatch Format No. of Copies"; "Dispatch Format No. of Copies")
                {
                    ApplicationArea = all;
                }
                field("Item Label Format"; "Item Label Format")
                {
                    editable = false;
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        PalletProccessSetup: Record "Pallet Process Setup";
                        StickerFormat: Record "Sticker Format";
                        Err001: Label 'Item Label Format is not Setup, Please contact system admin';
                        StickerFormatPage: page "Sticker Formats";
                    begin
                        PalletProccessSetup.get;
                        if PalletProccessSetup."Dispatch Type Code" <> '' then begin
                            CLEAR(StickerFormatPage);
                            StickerFormatPage.LOOKUPMODE := TRUE;
                            StickerFormat.reset;
                            StickerFormat.setrange("Format Type", PalletProccessSetup."Item Label Type Code");
                            //if StickerFormat.findset then begin
                            StickerFormatPage.SETRECORD(StickerFormat);
                            StickerFormatPage.SETTABLEVIEW(StickerFormat);
                            IF StickerFormatPage.RUNMODAL = ACTION::LookupOK THEN BEGIN
                                StickerFormatPage.GETRECORD(StickerFormat);
                                rec."Item Label Format" := StickerFormat."Sticker Description";
                                rec.modify;
                            END;
                            //end;

                        end
                        else
                            error(Err001);
                    end;
                }
                field("SSCC Sticker Note"; "SSCC Sticker Note")
                {
                    ApplicationArea = all;
                }
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