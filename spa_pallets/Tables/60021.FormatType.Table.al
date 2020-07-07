table 60021 "Format Type"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;Code; Code[20])
        {
            DataClassification = ToBeClassified;
            caption='Format Code';
        }

        field(20;Description; Text[50])
        {
            DataClassification = ToBeClassified;
            caption='Format Description';
        }        
    }
    
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
    
    var
        myInt: Integer;
    
    trigger OnInsert()
    begin
        
    end;
    
    trigger OnModify()
    begin
        
    end;
    
    trigger OnDelete()
    begin
        
    end;
    
    trigger OnRename()
    begin
        
    end;
    
}