codeunit 50104 "Upload Actions"
{
    procedure ReleaseSOCreateWSReleaseWS(salesHeaderNumber: Text): Text;
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipment: Record "Warehouse Shipment Header";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        ResultText: Text;
    begin
        ResultText := '';
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, salesHeaderNumber) then exit(ResultText);
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
        if SalesHeader.Status <> SalesHeader.Status::Released then
            exit(ResultText)
        else
            ResultText := ResultText + "SalesHeader"."No.";
        CreateWarehouseShipments(SalesHeader);
        ReleaseWarehouseShipments(SalesHeader, ResultText);
        exit(ResultText);
    end;


    local procedure CreateWarehouseShipments(SalesHeader: Record "Sales Header");
    var
        WhseRequest: record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        // filter whse requests
        WhseRequest.SETRANGE(Type, WhseRequest.Type::Outbound);
        WhseRequest.SETRANGE("Source Type", 37); // 37 = Sales order
        WhseRequest.SETRANGE("Source Subtype", SalesHeader."Document Type");
        WhseRequest.SETRANGE("Source No.", SalesHeader."No.");
        // Create warehouse shipments (taken from cu 5752 Get Source Doc. Outbound, CreateWhseShipmentHeaderFromWhseRequest)
        if WhseRequest.Findset then begin
            Clear(GetSourceDocuments);
            GetSourceDocuments.SetHideDialog(true);
            GetSourceDocuments.UseRequestPage(false);
            GetSourceDocuments.SetTableView(WhseRequest);
            GetSourceDocuments.RunModal;
        end;
    end;

    local procedure ReleaseWarehouseShipments(SalesHeader: Record "Sales Header";
    var ResultText: Text);
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        // Loop through new Warehouse Shipments for given Sales Header, and paste them into the output array variable
        WarehouseShipmentLine.Reset();
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Assemble to Order");
        WarehouseShipmentLine.SetRange("Source Type", 37); // 37 = Sales Line
        WarehouseShipmentLine.SetRange("Source Subtype", 1); // 1 = Order
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        if WarehouseShipmentLine.Findset() then //repeat -- for later if they ever have multiple shipments per sales order
            if WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.") then
                if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Open then begin
                    WhseShipmentRelease.Release(WarehouseShipmentHeader);
                    if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Released then ResultText := ResultText + '|' + WarehouseShipmentHeader."No.";
                end;
        //until WarehouseShipmentLine.Next() = 0;
    end;

    procedure PostWarehouseShipment(warehouseShipmentNumber: Code[20];
    ShipmentMethodCode: code[10];
    ShippingAgentCode: code[10];
    ShippingAgentServiceCode: code[10];
    PackageTrackingNo: Text[30];
    Invoice: boolean): text;
    var
        SalesHeader: Record "Sales Header";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LastShippingNo: code[20];
    begin
        if not WhseShipmentHeader.Get(warehouseShipmentNumber) then exit('');
        // we are assuming that every warehouse shipment line is for the same Sales Order
        WhseShipmentLine.Reset();
        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
        if not WhseShipmentLine.FindSet() then exit('');
        if not SalesHeader.Get(WhseShipmentLine."Source Subtype", WhseShipmentLine."Source No.") then exit('');
        // add Shipping fields to Sales Header and Warehouse Shipment Header
        SalesHeader.SuspendStatusCheck(true);
        if PackageTrackingNo <> '' then begin
            SalesHeader."Package Tracking No." := PackageTrackingNo;
            SalesHeader.Modify(); // there is no OnModify trigger
        end;
        // WhseShipmentHeader does not have a PackageTrackingNo field
        // All other fields can be updated on the Warehouse Shipment and will transfer to Sales Header
        if ShipmentMethod.Get(ShipmentMethodCode) then WhseShipmentHeader."Shipment Method Code" := ShipmentMethodCode;
        if ShippingAgent.Get(ShippingAgentCode) then WhseShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        if ShippingAgentServices.Get(ShippingAgentCode, ShippingAgentServiceCode) then WhseShipmentHeader."Shipping Agent Service Code" := ShippingAgentServiceCode;
        WhseShipmentHeader.Modify(); // there is no OnModify trigger
                                     // set conditions for posting
        WhsePostShipment.SetPostingSettings(Invoice); // Invoice = false will Ship; true will Ship/Invoice
        WhsePostShipment.SetPrint(false);
        LastShippingNo := WhseShipmentHeader."Last Shipping No.";
        // post shipment
        WhsePostShipment.Run(WhseShipmentLine);
        Clear(WhsePostShipment);
        // find posted whse shipment #
        PostedWhseShipmentHeader.Reset();
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", warehouseShipmentNumber);
        if not PostedWhseShipmentHeader.FindLast() then
            exit('')
        else
            if PostedWhseShipmentHeader."No." = LastShippingNo then
                exit('')
            else
                exit(WhseShipmentHeader."No." + '|' + PostedWhseShipmentHeader."No.");
        /*
              // find posted sales shipment #
              SalesShipmentHeader.Reset();
              SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
              if not SalesShipmentHeader.FindLast() then
                  exit(PostedWhseShipmentHeader."No.")
              else
                  exit(PostedWhseShipmentHeader."No." + '|' + SalesShipmentHeader."No.");
              */
    end;
}