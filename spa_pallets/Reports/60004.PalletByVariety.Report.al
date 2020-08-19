report 60004 "Pallet By Variety"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = './Layout/PalletByVariety.rdl';
    Caption = 'Pallet By Variety';

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("No.");
            //RequestFilterFields = "Sell-to Customer No.";
            RequestFilterHeading = 'header filter';
            column(CustName; tempCustomer.Name)
            {

            }
            column(CurrentDate; CurrentDate)
            {

            }
            column(CurrentDay; CurrentDay)
            {

            }
            column(Pack_out_Date; "Pack-out Date")
            {

            }
            dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
            {
                DataItemLink = "Source No." = FIELD("No.");
                DataItemLinkReference = "Sales Header";
                DataItemTableView = SORTING("Item No.") WHERE("Source Document" = CONST(1));
                column("WSL_No"; "No.")
                {

                }
                column("LineNo"; "Line No.")
                {

                }
                column(ItemNo; "Item No.")
                {

                }

                column(ColumnName; tempItem."Variant Filter")
                {

                }
                dataitem("Warehouse Pallet"; "Warehouse Pallet")
                {
                    DataItemLink = "Whse Shipment No." = FIELD("No."),
                               "Whse Shipment Line No." = FIELD("Line No.");
                    DataItemTableView = sorting("Pallet Id");
                    column(Palletid; "Pallet ID")
                    {

                    }
                    column("No"; "Whse Shipment No.")
                    {

                    }
                    dataitem("Pallet Line"; "Pallet Line")
                    {

                        DataItemLink = "Pallet ID" = FIELD("Pallet ID");
                        DataItemTableView = sorting("Pallet Id");
                        column(PalletidLine; "Pallet ID")
                        {

                        }
                        column(PalletidLineLbl; PalletIdLbl)
                        {

                        }
                        column(PalletLineNo; "Line No.")
                        {

                        }
                        column(LotNo; "Lot Number")
                        {

                        }

                        column(QuantityLine; "Quantity")
                        {

                        }
                        column(QuantityLineLbl; QuantityLbl)
                        {

                        }
                        column(VariantCode; "Variant Code")
                        {

                        }
                        column(VarientName; tempItemVariant.Description)
                        {

                        }
                        column(VarientNameLbl; VarietyLbl)
                        {

                        }

                        column(Container; Container)
                        {

                        }
                        column(ContainerLbl; ContainerLbl)
                        {

                        }
                        column(Grade; Grade)
                        {

                        }
                        column(GradeLbl; GradeLbl)
                        {

                        }
                        column(Size; Size)
                        {

                        }
                        column(SizeLbl; SizeLbl)
                        {

                        }

                        trigger OnAfterGetRecord() //PALLET LINE
                        var

                        begin
                            tempItemVariant.Reset();
                            tempItemVariant.Get("Warehouse Shipment Line"."Item No.", "Pallet Line"."Variant Code");

                            Container := GetItemItemAttributeA("Item No.", 'Packaging Description');
                            Grade := GetItemItemAttributeA("Item No.", 'Grade');
                            Size := GetItemItemAttributeA("Item No.", 'Size');
                        end;

                    } //end - pallet LIne
                    trigger OnAfterGetRecord() //WARHOUSE PALLET
                    var

                    begin
                        tempPalletLine.Reset();
                        tempPalletLine.Get("Pallet ID", "Pallet Line No.");
                        if (tempPalletLine.FindFirst()) then begin
                            tempItemVariant.Reset();
                            tempItemVariant.Get(tempPalletLine."Item No.", tempPalletLine."Variant Code")
                        end;
                        // if (!tempPallet) then
                        //     tempPallet :=  tempPalletLine."Pallet ID";
                        // if (tempPallet != tempPalletLine."Pallet ID") then 
                        // begin
                        //       TotalContainerQty := 0;
                        // tempPallet := tempPalletLine."Pallet ID";
                        //  end;                   

                    end;
                } //end-warhouse pallet
            }//end  Warehouse Shipment Line                     

            trigger OnPreDataItem()
            var
                myInt: Integer;
            begin
                IF CustomerNum <> '' THEN
                    "Sales Header".SetRange("Sell-to Customer No.", CustomerNum);
                // if CustomerNum = '' THEN
                //     error('לא נבחר לקוח');
                IF FromDate > 0D THEN
                    "Sales Header".SetFilter("Dispatch Date", '>=%1', FromDate);
                IF ToDate > 0D THEN
                    "Sales Header".SetFilter("Dispatch Date", '<=%1', ToDate);
                IF (FromDate > 0D) AND (ToDate > 0D) THEN
                    "Sales Header".SetRange("Dispatch Date", FromDate, ToDate);
            end;


            trigger OnAfterGetRecord()
            var

            begin
                tempCustomer.Get("Sell-to Customer No.");
            end;
        }//end-header

    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field("From Date"; FromDate)

                {

                    ApplicationArea = All;
                    // NotBlank = true;
                    // trigger OnValidate()
                    // var
                    // begin
                    //     // if (FromDate = 0D) then
                    //     //     error('תאריך');
                    // end;
                }

                field("To Date"; ToDate)
                {
                    ApplicationArea = ALL;
                }

                field("Customer number"; CustomerNum)
                {
                    ApplicationArea = ALL;
                    TableRelation = Customer."No.";

                }
            }
        }
        actions
        {
            area(Processing)
            {

            }
        }
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            //IF CloseAction IN [ACTION::OK, ACTION::LookupOK] THEN BEGIN
            if CloseAction <> CloseAction::Cancel then
                IF CustomerNum = '' THEN ERROR('לא נבחר לקוח');
        END;
    }

    trigger OnInitReport()
    var
        myInt: Integer;
    begin
        CurrentDate := Format(Today, 0, '<Day,2> <Month Text,4> <Year4>');
        //CurrentDate := Format(Today, 0, '<Day,2> <Month Text,4> <Year>');            
        //CurrentDayNum := 1;
        CurrentDayNum := Date2DWY(Today, 1);
        CASE CurrentDayNum OF
            1:
                BEGIN
                    CurrentDay := 'Monday';
                    EXIT;
                END;
            2:
                BEGIN
                    CurrentDay := 'Tuesday';
                    EXIT;

                END;
            3:
                BEGIN
                    CurrentDay := 'Wednesday';
                    EXIT;
                END;
            4:
                BEGIN
                    CurrentDay := 'Thursday';
                    EXIT;
                END;

            5:
                BEGIN
                    CurrentDay := 'Friday';
                    EXIT;
                END;
            6:
                BEGIN
                    CurrentDay := 'Saturday';
                    EXIT;
                END;
            7:
                BEGIN
                    CurrentDay := 'Sunday';
                    EXIT;
                END;
        END;

    end;

    var

        currentdatetoday: Date;
        CurrentDate: text;
        CurrentDayNum: Integer;
        CurrentDay: text;
        tempCustomer: Record Customer;
        tempItemVariant: record "Item Variant";
        tempItem: Record "Item";
        tempPalletLine: Record "Pallet Line";
        FromDate: Date;
        ToDate: Date;
        CustomerNum: Code[20];
        Container: text;
        Grade: text;
        Size: text;
        VarietyLbl: Label 'Variety';
        ContainerLbl: Label 'Container';
        GradeLbl: label 'Grade';
        SizeLbl: label 'Count/Size/Wt';
        QuantityLbl: Label 'Number';
        PalletIdLbl: Label 'Pallet Id';
        OldPalletNoLbl: Label 'Old Pallet No';
        PackIdLbl: Label 'PackId';


    procedure GetItemItemAttributeA(var pItemNo: Code[20]; pItemAttributeName: Text): Text
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        itemAttributeValue: Record "Item Attribute Value";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeID: Integer;

    begin
        ItemAttribute.Reset();
        ItemAttribute.SetRange(Name, pItemAttributeName);
        if ItemAttribute.FindFirst() then
            ItemAttributeID := ItemAttribute.ID;


        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", pItemNo);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttributeID);
        if ItemAttributeValueMapping.FindFirst() then begin

            itemAttributeValue.Reset();
            itemAttributeValue.SetRange("Attribute ID", ItemAttributeValueMapping."Item Attribute ID");
            itemAttributeValue.SetRange(ID, ItemAttributeValueMapping."Item Attribute Value ID");
            // itemAttributeValue.SetRange(Blocked, true);
            if itemAttributeValue.FindFirst() then
                exit(itemAttributeValue.Value);

        end;
        exit('');
    end;
}