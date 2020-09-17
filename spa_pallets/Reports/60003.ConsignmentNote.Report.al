report 60003 "Consignment Note"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    // DefaultLayout = Word;
    DefaultLayout = RDLC;
    // WordLayout = './Layout/ConsignmentNote.docx';
    RDLCLayout = './Layout/ConsignmentNote.rdl';
    Caption = 'Consigment Note';

    dataset
    {

        dataitem("Posted Whse. Shipment Line"; "Posted Whse. Shipment Line")
        {
            DataItemTableView = WHERE("Source Document" = CONST(1));
            // RequestFilterFields = "Source No.";
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
            column(CompanyInfoABN; CompanyInfo.ABN)
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
            column(ConNote; GSalesOrder)
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
            column(CustomerAddress; ShiptoAddress)
            {

            }
            // column(ShipmentAddress; tempSalesHeader."Ship-to Address")
            // {

            // }

            column(PoNumber; ExtDocNo)
            {

            }
            column(PoNumberLbl; PoNumberLbl)
            {

            }
            column(DeliveyDate; Format(RD))
            {

            }
            column(DeliveyDateLbl; DeliveryDateLbl)
            {

            }
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
            dataitem("Posted Warehouse Pallet"; "Posted Warehouse Pallet")
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


            trigger OnPreDataItem()
            var
                myInt: Integer;

            begin
                // If (FromDate > 0D) and (ToDate > 0D) then
                //     "Sales Header".SetFilter("Dispatch Date", '%1..%2', FromDate, ToDate);
                // if (CustomerNum <> '') then
                //     "Sales Header".SetRange("Sell-to Customer No.", CustomerNum);
                if (NumOrder <> '') then
                    "Posted Whse. Shipment Line".SetRange("Source No.", NumOrder);
                //"Sales Header".SetRange("Dispatch Date", FromDate, ToDate);

            end;

            trigger OnAfterGetRecord()
            var
                LSalesHeader: Record "Sales Header";
                LArchiveSalesHeader: Record "Sales Header Archive";
            begin
                GSalesOrder := '';
                ExtDocNo := '';
                RD := 0D;
                ShiptoAddress := '';
                LArchiveSalesHeader.Reset();
                LArchiveSalesHeader.SetRange("Document Type", LArchiveSalesHeader."Document Type"::Order);
                LArchiveSalesHeader.SetRange("No.", "Posted Whse. Shipment Line"."Source No.");
                if LArchiveSalesHeader.FindFirst() then begin
                    tempCustomer.Get(LArchiveSalesHeader."Sell-to Customer No.");
                    GSalesOrder := LArchiveSalesHeader."No.";
                    if (LArchiveSalesHeader."Ship-to Code" <> '') and (LArchiveSalesHeader."Ship-to Address" <> '') then
                        ShiptoAddress := LArchiveSalesHeader."Ship-to Address" + ', '
                                        + LArchiveSalesHeader."Ship-to City" + ', '
                                        + LArchiveSalesHeader."Ship-to Post Code" + ', '
                                        + LArchiveSalesHeader."Ship-to Country/Region Code"
                    else
                        ShiptoAddress := tempCustomer."Address" + ', '
                                           + tempCustomer."City" + ', '
                                           + tempCustomer."Post Code" + ', '
                                           + tempCustomer."Country/Region Code";
                    ExtDocNo := LArchiveSalesHeader."External Document No.";
                    RD := LArchiveSalesHeader."Requested Delivery Date";

                end else begin
                    if LSalesHeader.get(LSalesHeader."Document Type"::Order, "Posted Whse. Shipment Line"."Source No.") then begin
                        tempCustomer.Get(LSalesHeader."Sell-to Customer No.");
                        GSalesOrder := LSalesHeader."No.";
                        if (LSalesHeader."Ship-to Code" <> '') and (LSalesHeader."Ship-to Address" <> '') then
                            ShiptoAddress := LSalesHeader."Ship-to Address" + ', '
                                            + LSalesHeader."Ship-to City" + ', '
                                            + LSalesHeader."Ship-to Post Code" + ', '
                                            + LSalesHeader."Ship-to Country/Region Code"
                        else
                            ShiptoAddress := tempCustomer."Address" + ', '
                                               + tempCustomer."City" + ', '
                                               + tempCustomer."Post Code" + ', '
                                               + tempCustomer."Country/Region Code";
                        ExtDocNo := LSalesHeader."External Document No.";
                        RD := LSalesHeader."Requested Delivery Date";
                    end;
                end;
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

                field(NumOrder; NumOrder)
                {
                    Caption = 'Order Number';
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LPostedWHShipmentLinePage: Page "Posted Whse. Shipment Lines";
                        LPostedWhShipmentLine: Record "Posted Whse. Shipment Line";
                    begin
                        CLEAR(LPostedWHShipmentLinePage);
                        LPostedWhShipmentLine.Reset();
                        LPostedWHShipmentLinePage.SETRECORD(LPostedWhShipmentLine);
                        LPostedWHShipmentLinePage.SETTABLEVIEW(LPostedWhShipmentLine);
                        LPostedWHShipmentLinePage.LOOKUPMODE(TRUE);
                        IF LPostedWHShipmentLinePage.RUNMODAL = ACTION::LookupOK THEN BEGIN
                            LPostedWHShipmentLinePage.GETRECORD(LPostedWhShipmentLine);
                            NumOrder := LPostedWhShipmentLine."Source No.";
                        end;
                    end;
                }

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
        GSalesOrder: Code[20];
        ExtDocNo: Code[20];
        RD: Date;
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
        ShiptoAddress: text;
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