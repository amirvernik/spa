codeunit 60032 DisposePalletWorkflowInit
{
    trigger OnRun()
    begin

    end;

    [IntegrationEvent(false, false)]
    PROCEDURE OnSendDisposePalletforApproval(var PalletHeader: Record "Pallet Header");
    begin
    end;

    procedure IsDisposePalletEnabled(var PalletHeader: Record "Pallet Header"): Boolean
    var
        WFMngt: Codeunit "Workflow Management";
        WFCode: Codeunit "Dispose Pallet Workflow";
    begin
        exit(WFMngt.CanExecuteWorkflow(PalletHeader, WFCode.RunWorkflowOnSendDisposePalletApprovalCode()))
    end;

    local procedure CheckWorkflowEnabled(): Boolean
    var
        PalletHeader: Record "Pallet Header";
        LblNoWorkflowEnb: Label 'No workflow Enabled for this Record type';
    begin
        if not IsDisposePalletEnabled(PalletHeader) then
            Error(LblNoWorkflowEnb);
    end;



    var
        myInt: Integer;
}