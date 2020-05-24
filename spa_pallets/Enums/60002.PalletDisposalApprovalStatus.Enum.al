enum 60002 "Pallet Disposal approval Status"
{
    Extensible = true;

    value(0; Open)
    {
        caption = 'Open';
    }
    value(1; Released)
    {
        caption = 'Released';
    }
    value(2; "Pending Approval")
    {
        caption = 'Pending approval';
    }
    value(3; Rejected)
    {
        caption = 'Rejected';
    }
    value(4; Delegated)
    {
        caption = 'Delegated';
    }

}