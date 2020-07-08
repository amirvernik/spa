tableextension 60009 SalesHeaderExt extends "Sales Header"
{
    fields
    {

        field(60000; "User Created"; code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "SPA Location"; code[20])
        {
            DataClassification = ToBeClassified;
        } 
        field(60002;"Dispatch Date";date)
        {
            DataClassification=ToBeClassified;
        }  
        field(60003;"Packing Days";Integer)
        {
            DataClassification=ToBeClassified;
        }
        field(60004;"Pack-out Date";date)
        {
            DataClassification=ToBeClassified;
        }     
    }

    var
        myInt: Integer;
}