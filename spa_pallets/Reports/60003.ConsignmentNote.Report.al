report 60003 "Consignment Note"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    // DefaultLayout = Word;
    DefaultLayout = RDLC;
    WordLayout = './Layout/ConsignmentNote.docx';
    RDLCLayout = './Layout/ConsignmentNote.rdl';
    Caption = 'consigment Note';

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("No.");
            // RequestFilterFields = "Sell-to Customer No.", "Dispatch Date";
            //RequestFilterFields = "No.", "Sell-to Customer No.";
            RequestFilterHeading = 'header filter';
            column(TodayDate; TodayDate)
            {
                // AutoFormatExpression =  DT2Date();
            }
            column(CurrentTime; CurrentTime)
            {
                // AutoFormatExpression =  DT2Date();
            }
            column(CurrentTimeLbl; DeliveryTimeLbl)
            {
                // AutoFormatExpression =  DT2Date();
            }
            column(CompanyInfoPicture; CompanyInfo.Picture)
            {

            }
            column(CompanyInfoName; CompanyInfo.Name)
            {

            }
            column(CompanyInfoAddress; CompanyInfo.Address)
            {

            }

            column(CompanyInfoCity; CompanyInfo.City)
            {

            }
            column(CompanyInfoCountry; CompanyInfo.County)
            {

            }
            column(CompanyInfoPostCode; CompanyInfo."Post Code")
            {

            }
            column(CompanyInfoPhone; CompanyInfo."Phone No.")
            {

            }
            column(CompanyInfoPhoneLbl; PhoneLbl)
            {

            }
            column(CompanyInfoFax; CompanyInfo."Fax No.")
            {

            }
            column(CompanyInfoFaxLbl; FaxLbl)
            {

            }
            //shipment number
            // column(Number; "No.")
            // {

            // }
            column(ConNote; "No.")
            {

            }
            // column(ConNoteHeader; "No.")
            // {

            // }
            column(numberLbl; ConLbl)
            {

            }
            column(CustName; tempCustomer.Name)
            {

            }
            column(CustNameLbl; AgentCustomerLbl)
            {

            }
            column(CustomerAddress; tempCustomer.Address)
            {

            }
            // column(ShipmentAddress; tempSalesHeader."Ship-to Address")
            // {

            // }

            column(PoNumber; "External Document No.")
            {

            }
            column(PoNumberLbl; PoNumberLbl)
            {

            }
            // column(DeliveyDate; Format("Shipment Date"))
            // {

            // }
            column(DeliveyDate; Format("Requested Delivery Date"))
            {

            }
            column(DeliveyDateLbl; DeliveryDateLbl)
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

                column(Quantity; Quantity)
                {

                }
                column(QuantityLbl; QuantityLbl)
                {

                }
                column(ColumnName; tempItem."Variant Filter")
                {

                }
                dataitem("Warehouse Pallet"; "Warehouse Pallet")
                {
                    DataItemLink = "Whse Shipment No." = FIELD("No."),
                                   "Whse Shipment Line No." = FIELD("Line No."),
                               "Sales Order No." = FIELD("Source No."),
                               "Sales Order Line No." = field("Source Line No.");
                    DataItemTableView = sorting("Pallet Id");
                    column(Palletid; "Pallet ID")
                    {

                    }
                    column("No"; "Whse Shipment No.")
                    {

                    }
                    dataitem("Pallet Line"; "Pallet Line")
                    {

                        DataItemLink = "Pallet ID" = FIELD("Pallet ID")
                                       , "Line No." = FIELD("Pallet Line No.")
                                       , "Lot Number" = FIELD("Lot No.");
                        DataItemTableView = sorting("Pallet Id");
                        column(PalletidLine; "Pallet ID")
                        {

                        }
                        column(PalletLineNo; "Line No.")
                        {

                        }
                        column(LotNo; "Lot Number")
                        {

                        }
                        column(LotNoLbl; BatchLbl)
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
                        column(VarientName; ItemVarietyDescription)
                        {

                        }
                        column(VarientNameLbl; VarietyLbl)
                        {

                        }
                        column(TotalContainerQty; TotalContainerQty)
                        {

                        }
                        column(TotalContainerQtyLbl; TotalContainerLbl)
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
                        column(TotalCustomerQtyLbl; TotalCustomerLbl)
                        {

                        }

                        trigger OnAfterGetRecord() //PALLET LINE
                        var
                        begin

                            if ItemVariety.Get("Pallet Line"."Item No.", copystr("Pallet Line"."Variant Code", 1, 10)) then
                                ItemVarietyDescription := ItemVariety.Description;
                            Container := GetItemItemAttributeA("Item No.", 'Packaging Description');
                            Grade := GetItemItemAttributeA("Item No.", 'Grade');
                            Size := GetItemItemAttributeA("Item No.", 'Size');
                        end;

                    } //end - pallet LIne
                    trigger OnAfterGetRecord() //WARHOUSE PALLET
                    var

                    begin
                        TotalContainerQty := 0;
                        if tempPallet <> "Pallet Line"."Pallet ID" then begin
                            NumberOfPallet := NumberOfPallet + 1;
                            tempPallet := "Pallet Line"."Pallet ID";
                        end;

                    end;
                } //end-warhouse pallet

            } //end-line

            trigger OnPreDataItem()
            var
                myInt: Integer;
            begin
                // If (FromDate > 0D) and (ToDate > 0D) then
                //     "Sales Header".SetFilter("Dispatch Date", '%1..%2', FromDate, ToDate);
                // if (CustomerNum <> '') then
                //     "Sales Header".SetRange("Sell-to Customer No.", CustomerNum);
                if (NumOrder <> '') then
                    "Sales Header".SetRange("No.", NumOrder);
                //"Sales Header".SetRange("Dispatch Date", FromDate, ToDate);

            end;

            trigger OnAfterGetRecord()
            var

            begin
                tempCustomer.Get("Sell-to Customer No.");
                TotalCustomerQty := 0;
                NumberOfPallet := 0;
            end;

        } //end-header         

    }
    requestpage

    {

        layout

        {


            area(Content)

            {

                /*   field("From Date"; FromDate)

                   {

                       ApplicationArea = All;
                       NotBlank = true;
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
                       TableRelation = Customer;

                   }*/
                //field("Sales Order Number"; NumOrder)
                //{
                //  ApplicationArea = ALL;
                //  TableRelation = "Sales Header"."No.";



                // CLEAR(myTabfrm);
                // myRec.RESET();
                // myTabfrm.SETTABLEVIEW(myRec) ;
                // myTabfrm.LOOKUPMODE(TRUE) ;
                // IF myTabfrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                // myTabfrm.GETRECORD(myRec);
                // SETFILTER(text,myRec.text);
                // END;
                //}


            }


        }

    }


    trigger OnInitReport()
    var
        myInt: Integer;
    begin
        CompanyInfo.get;
        CompanyInfo.CalcFields(picture);
        // TodayDate := Format(Today, 0, 4);
        // Date2DWY(,1)
        TodayDate := Format(Today, 0, '<Day,2>-<Month Text,3>-<Year>');
        CurrentTime := Format(Time, 0, '<HOUR,2>:<MINUTE,2>:<SECOND,2>');


    end;

    // trigger OnPreReport()
    // var

    // begin
    //     if (ToDate = 0D) then
    //         Message('נא להכניס תאריך');


    // end;

    var
        myInt: Integer;
        ItemVarietyDescription: Text;
        ItemVariety: Record "Item Variant";

        tempCustomer: Record Customer;

        tempItem: Record "Item";

        TotalCustomerQty: Decimal;
        TotalContainerQty: Decimal;
        NumberOfPallet: Integer;
        tempPallet: Code[20];
        CompanyInfo: Record "Company Information";

        TodayDate: text;
        CurrentTime: text;
        Container: text;
        Grade: text;
        Size: text;


        NumOrder: Code[20];
        PhoneLbl: Label 'Phone:';
        FaxLbl: Label 'Fax:';
        ConLbl: Label 'Con Note #:';
        PoNumberLbl: Label 'Po Number:';
        AgentCustomerLbl: Label 'Agent/Customer';
        DeliveryDateLbl: Label 'Delivery Date: ';
        DeliveryTimeLbl: Label 'Delivery Time:';

        RefLbl: Label 'Ref #';
        BatchLbl: label 'BatchCode';
        VarietyLbl: Label 'Variety';
        ContainerLbl: Label 'Container';
        GradeLbl: label 'Grade';
        SizeLbl: label 'Size';
        QuantityLbl: Label 'No';
        TotalContainerLbl: Label 'Container Total:';
        TotalCustomerLbl: Label 'Customer Total:';

    procedure GetItemItemAttribute(var pItemNo: Code[20]; pItemAttributeName: Text): Text
    var

        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        itemAttributeValueSelection: Record "Item Attribute Value Selection";
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
        if ItemAttributeValueMapping.FindFirst() then
            exit(format(ItemAttributeValueMapping."Item Attribute Value ID"));

    end;


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

    procedure UpdateReport(var salesHeader: record "Sales Header")

    begin
        NumOrder := salesHeader."No.";
    end;

}