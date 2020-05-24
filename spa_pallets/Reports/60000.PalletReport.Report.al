report 60000 "Pallet Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    CaptionML = ENU = 'Pallet Report';
    DefaultLayout = RDLC; // if Word use WordLayout property
    RDLCLayout = './Layout/PalletReport.rdl';


    dataset
    {
        dataitem("Pallet Header"; "Pallet Header")
        {
            RequestFilterFields = "Pallet ID", "Pallet Status", "Location Code";
            column(Pallet_ID; "Pallet ID")
            {

            }
            column(Pallet_Status; "Pallet Status")
            {

            }
            column(Location_Code; "Location Code")
            {

            }
        }
    }


}