page 60005 "Pallet Process Setup"
{

    PageType = Card;
    SourceTable = "Pallet Process Setup";
    Caption = 'SPA General Setup';
    UsageCategory = Administration;
    ApplicationArea = all;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Pallet No. Series"; "Pallet No. Series")
                {
                    ApplicationArea = All;
                }
                field("Cancel Reason Code"; "Cancel Reason Code")
                {
                    ApplicationArea = All;
                }
                field("Password Pallet Management"; "Password Pallet Management")
                {
                    ApplicationArea = all;
                }

            }
            group("Item Reclass Journals")
            {
                field("Item Reclass Template"; "Item Reclass Template")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CLEAR(PageLookupTemplate);
                        PageLookupTemplate.LOOKUPMODE := TRUE;
                        LookupTemplate.reset;
                        LookupTemplate.setrange(LookupTemplate.Type, LookupTemplate.type::Transfer);
                        PageLookupTemplate.SETRECORD(LookupTemplate);
                        PageLookupTemplate.SETTABLEVIEW(LookupTemplate);


                        IF PageLookupTemplate.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            PageLookupTemplate.GETRECORD(LookupTemplate);
                            rec."Item Reclass Template" := LookupTemplate.Name;
                            rec.modify;
                        END;

                    end;
                }
                field("Item Reclass Batch"; "Item Reclass Batch")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        PalletProcessSetup.get;
                        if PalletProcessSetup."Item Reclass Template" <> '' then begin
                            CLEAR(PageLookupBatch);
                            PageLookupBatch.LOOKUPMODE := TRUE;
                            LookupBatche.reset;
                            LookupBatche.setrange("Journal Template Name", PalletProcessSetup."Item Reclass Template");
                            PageLookupBatch.SETRECORD(LookupBatche);
                            PageLookupBatch.SETTABLEVIEW(LookupBatche);

                            IF PageLookupBatch.RUNMODAL = ACTION::LookupOK THEN BEGIN
                                PageLookupBatch.GETRECORD(LookupBatche);
                                rec."Item Reclass Batch" := LookupBatche.Name;
                                rec.modify;
                            END;
                        end
                        else
                            error(err001);

                    end;
                }
            }
            group("Item Journals")
            {
                field("Item Journal Batch"; "Item Journal Batch")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CLEAR(PageLookupBatch);
                        PageLookupBatch.LOOKUPMODE := TRUE;
                        LookupBatche.reset;
                        LookupBatche.setrange("Journal Template Name", 'ITEM');
                        PageLookupBatch.SETRECORD(LookupBatche);

                        PageLookupBatch.SETTABLEVIEW(LookupBatche);

                        IF PageLookupBatch.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            PageLookupBatch.GETRECORD(LookupBatche);
                            rec."Item Journal Batch" := LookupBatche.Name;
                            rec.modify;
                        END;

                    end;

                }
                field("Disposal Batch"; "Disposal Batch")
                {
                    ApplicationArea = all;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CLEAR(PageLookupBatch);
                        PageLookupBatch.LOOKUPMODE := TRUE;
                        LookupBatche.reset;
                        LookupBatche.setrange("Journal Template Name", 'ITEM');
                        PageLookupBatch.SETRECORD(LookupBatche);

                        PageLookupBatch.SETTABLEVIEW(LookupBatche);

                        IF PageLookupBatch.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            PageLookupBatch.GETRECORD(LookupBatche);
                            rec."Disposal Batch" := LookupBatche.Name;
                            rec.modify;
                        END;

                    end;
                }

            }
            group("UI")

            {
                Visible = false;
                field("Json Text Sample"; "Json Text Sample")
                {
                    visible = false;
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
            group("Sticker Notes")
            {
                field("Pallet Label Type Code"; "Pallet Label Type Code")
                {
                    ApplicationArea = all;
                }
                field("SSCC Label Type Code"; "SSCC Label Type Code")
                {
                    ApplicationArea = all;
                }
                field("Dispatch Type Code"; "Dispatch Type Code")
                {
                    ApplicationArea = All;
                }
                field("Item Label Type Code"; "Item Label Type Code")
                {
                    ApplicationArea = All;
                }
                field("SSCC Label No. of Copies"; "SSCC Label No. of Copies")
                {
                    BlankZero = true;
                    ApplicationArea = all;
                }
                field("Pallet Label No. of Copies"; "Pallet Label No. of Copies")
                {
                    BlankZero = true;
                    ApplicationArea = all;
                }
                field("Company Prefix"; "Company Prefix")
                {
                    ApplicationArea = all;
                }
                field("SSCC No. Series"; "SSCC No. Series")
                {
                    ApplicationArea = all;
                }
                field("Sticker API URI"; "Sticker API URI")
                {
                    visible = false;
                    ApplicationArea = all;
                }
            }
            group("One Drive")
            {

                field("OneDrive Directory ID"; "OneDrive Directory ID")
                {
                    ApplicationArea = all;
                }
                field("OneDrive Client ID"; "OneDrive Client ID")
                {
                    ApplicationArea = all;
                }
                field("OneDrive Client Secret"; "OneDrive Client Secret")
                {
                    ApplicationArea = all;
                }
                field("OneDrive Drive ID"; "OneDrive Drive ID")
                {
                    ApplicationArea = all;
                }
            }

        }
    }
    actions
    {
        area(Processing)
        {
            action("Check")
            {
                image = CheckList;
                Promoted = true;
                visible = false;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = all;
                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    Outstr: OutStream;
                    BearerToken: text;
                    OneDriveFunctions: Codeunit "OneDrive Functions";
                begin
                    TempBlob.CreateOutStream(OutStr);
                    Outstr.WriteText('Amir Vernik Test');
                    TempBlob.CreateInStream(InStr);
                    BearerToken := OneDriveFunctions.GetBearerToken();
                    OneDriveFunctions.UploadFile('123456789.txt', BearerToken, InStr);
                end;
            }
            action("Format Types")
            {
                Image = CodesList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = all;
                RunObject = page "Format Types";
            }
            action("Sticker Note Printers")
            {
                Image = PrintInstallment;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = all;
                trigger OnAction()
                begin
                    page.Run(page::"Sticker Note Printers");
                end;
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
        PageLookupBatch: page "Item Journal Batches";
        LookupBatche: Record "Item Journal Batch";
        PageLookupTemplate: page "Item Journal Template List";
        LookupTemplate: Record "Item Journal Template";
        PalletProcessSetup: Record "Pallet Process Setup";
        Err001: label 'You must specify Reclass Template';

}
