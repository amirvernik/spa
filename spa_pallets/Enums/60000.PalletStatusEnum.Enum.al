enum 60000 "Pallet Status"
{
    Extensible = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Closed)
    {
        Caption = 'Closed';
    }
    value(2; Shipped)
    {
        Caption = 'Shipped';
    }
    value(3; "Consumed")
    {
        Caption = 'Consumed';
    }
    value(4; Disposed)
    {
        caption = 'Disposed';
    }
    value(5; "Partially consumed")
    {
        caption = 'Partially consumed';
    }
    value(6; Canceled)
    {
        Caption = 'Canceled';
    }
}
