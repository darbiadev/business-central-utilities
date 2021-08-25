codeunit 50100 "SalesHeaderActionsDarbia"
{
    procedure ReleaseSalesHeader(salesHeaderNumber: Text): Text;
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        ResultText: Text;
    begin
        ResultText := '';

        if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNumber)
        then begin
            if SalesHeader.Status = SalesHeader.Status::Released
            then begin
                ResultText := "SalesHeader"."No." + ' was already released';
            end else begin
                ReleaseSalesDocument.PerformManualRelease(SalesHeader);
                if SalesHeader.Status = SalesHeader.Status::Released
                then begin
                    ResultText := "SalesHeader"."No." + ' was released';
                end else begin
                    ResultText := "SalesHeader"."No." + ' was unable to be released';
                end;
            end;
        end else begin
            ResultText := salesHeaderNumber + ' not found';
        end;

        exit(ResultText);
    end;
}
