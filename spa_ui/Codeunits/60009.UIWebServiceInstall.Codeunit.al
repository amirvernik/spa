codeunit 60009 "Install Web Service"
{

    Subtype = install;

    trigger OnInstallAppPerCompany()
    begin
        if not TenantWebService.get(TenantWebService."Object Type"::Codeunit, 'UIFunctions') then begin
            TenantWebService.Init();
            TenantWebService."Object Type" := TenantWebService."Object Type"::Codeunit;
            TenantWebService."Object ID" := 60008;
            TenantWebService."Service Name" := 'UIFunctions';
            TenantWebService.Published := true;
            TenantWebService.Insert(true);
        end;
    end;

    var
        TenantWebService: Record "Tenant Web Service";

}