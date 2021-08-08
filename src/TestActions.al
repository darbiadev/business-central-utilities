codeunit 50103 "Test Actions"
{
    procedure RegisterPick(warehouseActivityNumber: Code[20]): Text;
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
        ResultText: Text;
    begin
        ResultText := '';

        if WarehouseActivityHeader.Get(warehouseActivityNumber)
           then begin
            // WhseActivityPost.Run();
        end else begin
            ResultText := warehouseActivityNumber + ' not found';
        end;

        exit(ResultText);
    end;
}
