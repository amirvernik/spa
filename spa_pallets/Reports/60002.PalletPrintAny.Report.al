report 60002 "Pallet Print Any"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    UseRequestPage = true;
    CaptionML = ENU = 'Pallet Print Any';
    DefaultLayout = Word; // if Word use WordLayout property
    WordMergeDataItem = "pallet Header";
    WordLayout = './Layout/PalletPrintAny.docx';

    dataset
    {

        dataitem("Pallet Header"; "Pallet Header")
        {

            column(CompanyInfoPicture; CompanyInfo.Picture)
            {

            }
            column(Pallet_ID; "Pallet ID")
            {

            }
            column(Pallet_Status; "Pallet Status")
            {

            }
            column(Location_Code; "Location Code")
            {

            }
            column(Creation_Date; "Creation Date")
            {

            }
            column(User_Created; "User Created")
            {

            }
            column(Pallet_Type; "Pallet Type")
            {

            }
            dataitem(PalletLine; "Pallet Line")
            {
                DataItemLink = "Pallet ID" = field("Pallet ID");
                column(Item_No_; "Item No.")
                {

                }
                column(Quantity; Quantity)
                {

                }
                column(Description; Description)
                {

                }
                column(Lot_Number; "Lot Number")
                {

                }
                column(Expiration_Date; "Expiration Date")
                {
                }
                column(Unit_of_Measure; "Unit of Measure")
                {

                }

            }
        }
    }
    trigger OnInitReport()
    var
        myInt: Integer;
    begin
        CompanyInfo.get;
        CompanyInfo.CalcFields(picture);
    end;

    var
        CompanyInfo: Record "Company Information";

}