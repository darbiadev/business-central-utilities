codeunit 50101 "WarehouseShipmentHeaderActions"
{
    procedure ReleaseWarehouseShipmentHeader(warehouseShipmentHeaderNumber: Text): Text;
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReleaseWarehouseShipment: Codeunit "Whse.-Shipment Release";
        ResultText: Text;
    begin
        ResultText := '';

        if WarehouseShipmentHeader.Get(warehouseShipmentHeaderNumber)
        then begin
            if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Released
            then begin
                ResultText := "WarehouseShipmentHeader"."No." + ' was already released';
            end else begin
                ReleaseWarehouseShipment.Release(WarehouseShipmentHeader);
                if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Released
                then begin
                    ResultText := "WarehouseShipmentHeader"."No." + ' was released';
                end else begin
                    ResultText := "WarehouseShipmentHeader"."No." + ' was unable to be released';
                end;
            end;
        end else begin
            ResultText := warehouseShipmentHeaderNumber + ' not found';
        end;

        exit(ResultText);
    end;

    procedure ReopenWarehouseShipmentHeader(warehouseShipmentHeaderNumber: Text): Text;
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReleaseWarehouseShipment: Codeunit "Whse.-Shipment Release";
        ResultText: Text;
    begin
        ResultText := '';

        if WarehouseShipmentHeader.Get(warehouseShipmentHeaderNumber)
        then begin
            if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Open
            then begin
                ResultText := "WarehouseShipmentHeader"."No." + ' was already open';
            end else begin
                ReleaseWarehouseShipment.Reopen(WarehouseShipmentHeader);
                if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Open
                then begin
                    ResultText := "WarehouseShipmentHeader"."No." + ' was reopened';
                end else begin
                    ResultText := "WarehouseShipmentHeader"."No." + ' was unable to be reopened';
                end;
            end;
        end else begin
            ResultText := warehouseShipmentHeaderNumber + ' not found';
        end;

        exit(ResultText);
    end;
}