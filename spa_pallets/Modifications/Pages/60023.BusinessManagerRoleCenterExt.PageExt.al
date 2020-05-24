pageextension 60023 BusinessManagerRoleExt extends "Business Manager Role Center"
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
                        ApplicationArea = All;
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

                }

            }
        }
    }
}