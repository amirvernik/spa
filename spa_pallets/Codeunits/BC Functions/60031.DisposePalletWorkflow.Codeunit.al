codeunit 60031 "Dispose Pallet Workflow"
{
    trigger OnRun()
    begin

    end;

    var
        WFMngt: Codeunit "Workflow Management";
        AppMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowSetup: Codeunit "Workflow Setup";

        PDMngt: Codeunit "Pallet Disposal Management";

        PalletHeaderRec: Record "Pallet Header";

        ApprovalEntryTable: Record "Approval Entry";

        PalletDisposalApprovalStatus: enum "Pallet Disposal approval Status";

        LblSendDisposePalletReq: Label 'Approval Request for Dispose Pallet is requested';
        LblApprovalReqDisposePallet: Label 'Approval Request for Dispose Pallet is approved';
        LblRejectReqDisposePallet: Label 'Approval Request for Dispose Pallet is rejected';

        LblSendForPendAppTxt: Label 'Status of Dispose Pallet changed to Pending approval';
        LblReleaseDisposePalletTxt: Label 'Release Dispose Pallet';
        LblRejectDisposePalletTxt: Label 'Reject Dispose Pallet';

    procedure RunWorkflowOnSendDisposePalletApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendDisposePalletApproval'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::DisposePalletWorkflowInit, 'OnSendDisposePalletforApproval', '', false, false)]
    procedure RunWorkflowOnSendDisposePalletApproval(var PalletHeader: Record "Pallet Header")
    begin
        WFMngt.HandleEvent(RunWorkflowOnSendDisposePalletApprovalCode(), PalletHeader);
    end;

    procedure RunWorkflowOnApproveDisposePalletApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnApproveDisposePalletApproval'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnApproveApprovalRequest', '', false, false)]
    procedure RunWorkflowOnApproveDisposePalletApproval(var ApprovalEntry: Record "Approval Entry")
    begin
        WFMngt.HandleEventOnKnownWorkflowInstance(RunWorkflowOnApproveDisposePalletApprovalCode(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    procedure RunWorkflowOnRejectDisposePalletApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnRejectDisposePalletApproval'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    procedure RunWorkflowOnRejectDisposePalletApproval(var ApprovalEntry: Record "Approval Entry")
    begin
        WFMngt.HandleEventOnKnownWorkflowInstance(RunWorkflowOnRejectDisposePalletApprovalCode(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    procedure RunWorkflowOnDelegateDisposePalletApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnDelegateDisposePalletApproval'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDelegateApprovalRequest', '', false, false)]
    procedure RunWorkflowOnDelegateDisposePalletApproval(var ApprovalEntry: Record "Approval Entry")
    begin
        WFMngt.HandleEventOnKnownWorkflowInstance(RunWorkflowOnDelegateDisposePalletApprovalCode(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;


    procedure SetStatusToPendingApprovalCodeDisposePallet(): Code[128]
    begin
        exit(UpperCase('SetStatusToPendingApprovalDisposePallet'));
    end;

    procedure SetStatusToPendingApprovalDisposePallet(var Variant: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::"Pallet Header":
                begin
                    RecRef.SetTable(PalletHeaderRec);
                    PalletHeaderRec."Disposal Status" := PalletDisposalApprovalStatus::"Pending Approval";
                    PalletHeaderRec.Modify(true);
                    Variant := PalletHeaderRec;
                end;
        end;
    end;


    procedure SetStatusToApproveCodeDisposePallet(): Code[128]
    begin
        exit(UpperCase('SetStatusToApproveCodeDisposePallet'));
    end;

    procedure SetStatusToApproveCodeDisposePallet(var Variant: Variant)
    var
        RecRef: RecordRef;
        ApprovalEntry: Record "Approval Entry";
        PalletSetup: Record "Pallet Process Setup";
        ItemJournalLine: Record "Item Journal Line";
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    PalletHeaderRec.Reset();
                    PalletHeaderRec.SetRange(PalletHeaderRec."Pallet ID", ApprovalEntry."Document No.");
                    if PalletHeaderRec.FindFirst() then begin
                        Variant := PalletHeaderRec;
                        SetStatusToApproveCodeDisposePallet(Variant);
                    end;
                end;
            DATABASE::"Pallet Header":
                begin
                    RecRef.SetTable(PalletHeaderRec);
                    PalletHeaderRec."Disposal Status" := PalletDisposalApprovalStatus::Released;
                    PalletHeaderRec.Modify(true);

                    PalletSetup.get;
                    ItemJournalLine.reset;
                    ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                    ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Disposal Batch");
                    ItemJournalLine.SetRange("Document No.", PalletHeaderRec."Pallet ID");
                    if ItemJournalLine.findset then
                        ItemJournalLine.DeleteAll();

                    PDMngt.CheckDisposalSetup(PalletHeaderRec);
                    PDMngt.DisposePackingMaterials(PalletHeaderRec);
                    PDMngt.DisposePalletItems(PalletHeaderRec);
                    PDMngt.PostDisposalBatch(PalletHeaderRec."Pallet ID");
                    Variant := PalletHeaderRec;
                end;
        end;
    end;

    procedure SetStatusToRejectCodeDisposePallet(): Code[128]
    begin
        exit(UpperCase('SetStatusToRejectCodeDisposePallet'));
    end;

    procedure SetStatusToRejectCodeDisposePallet(var Variant: Variant)
    var
        RecRef: RecordRef;
        ApprovalEntry: Record "Approval Entry";
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    PalletHeaderRec.Reset();
                    PalletHeaderRec.SetRange(PalletHeaderRec."Pallet ID", ApprovalEntry."Document No.");
                    if PalletHeaderRec.FindFirst() then begin
                        Variant := PalletHeaderRec;
                        SetStatusToApproveCodeDisposePallet(Variant);
                    end;
                end;
            DATABASE::"Pallet Header":
                begin
                    RecRef.SetTable(PalletHeaderRec);
                    PalletHeaderRec."Disposal Status" := PalletDisposalApprovalStatus::Rejected;
                    PalletHeaderRec.Modify(true);
                    Variant := PalletHeaderRec;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', true, true)]
    procedure AddDisposePalletEventsToLibrary()
    begin
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendDisposePalletApprovalCode(), Database::"Pallet Header", LblSendDisposePalletReq, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnApproveDisposePalletApprovalCode(), Database::"Approval Entry", LblApprovalReqDisposePallet, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnRejectDisposePalletApprovalCode(), Database::"Approval Entry", LblRejectReqDisposePallet, 0, false);

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    procedure AddDisposePalletResponsesToLibrary()
    begin
        WorkflowSetup.InsertTableRelation(Database::"Pallet Header", 0, Database::"Approval Entry", 2);
        WorkflowResponseHandling.AddResponseToLibrary(SetStatusToPendingApprovalCodeDisposePallet(), 0, LblSendForPendAppTxt, 'GROUP 0');
        WorkflowResponseHandling.AddResponseToLibrary(SetStatusToApproveCodeDisposePallet(), 0, LblReleaseDisposePalletTxt, 'GROUP 0');
        WorkflowResponseHandling.AddResponseToLibrary(SetStatusToRejectCodeDisposePallet(), 0, LblRejectDisposePalletTxt, 'GROUP 0');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    procedure ExeRespForDisposePallet(var ResponseExecuted: Boolean; Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        IF WorkflowResponse.GET(ResponseWorkflowStepInstance."Function Name") THEN
            case WorkflowResponse."Function Name" of
                SetStatusToPendingApprovalCodeDisposePallet():
                    begin
                        SetStatusToPendingApprovalDisposePallet(Variant);
                        ResponseExecuted := true;
                    end;
                SetStatusToApproveCodeDisposePallet():
                    begin
                        SetStatusToApproveCodeDisposePallet(Variant);
                        ResponseExecuted := true;
                    end;
                SetStatusToRejectCodeDisposePallet():
                    begin
                        SetStatusToRejectCodeDisposePallet(Variant);
                        ResponseExecuted := true;
                    end;
            end;
    end;
}