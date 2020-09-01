pageextension 60022 OrderProcessorRoleExt extends "Order Processor Role Center"
{

    actions
    {
        addfirst(Sections)
        {
            group("SPA Custom")
            {

                // Creates a sub-menu
                group("Pallets")
                {
                    action("Pallet List")
                    {
                        RunObject = page "Pallet List";
                        ApplicationArea = All;
                    }
                    action("Pallet Ledger Entries")
                    {
                        RunObject = page "Pallet Ledger Entries";
                        ApplicationArea = All;
                    }
                    action("Pallet Change Quality")
                    {
                        RunObject = page "Pallet Change Quality";
                        ;
                        ApplicationArea = All;
                    }
                }
                group("Setups")
                {
                    action("SPA Purchase Process Setup")
                    {
                        RunObject = page "SPA Purchase Process Setup";
                        ApplicationArea = All;
                    }
                    action("Pallet Process Setup")
                    {
                        RunObject = page "Pallet Process Setup";
                        caption = 'SPA General Setup';
                        ApplicationArea = All;
                    }
                    action("Reservation Entries")
                    {
                        RunObject = page "Reservation Entries SPA";
                        Caption = 'Reservation entries';
                        ApplicationArea = all;
                    }
                }
                group("SPA Reports")
                {
                    Visible = true;

                    action("Pallet Report")
                    {
                        RunObject = report "Pallet Report";
                        ApplicationArea = All;
                    }
                    action("Pallet Print Any")
                    {
                        RunObject = report "Pallet Print Any";
                        ApplicationArea = All;
                    }
                    action("Consignment Report")
                    {
                        RunObject = page "Consignment Note Filetr";
                        ApplicationArea = All;
                    }
                    action("Pallet By Variety")
                    {
                        RunObject = report "Pallet By Variety";
                        ApplicationArea = All;
                    }

                }


            }
        }
    }
}