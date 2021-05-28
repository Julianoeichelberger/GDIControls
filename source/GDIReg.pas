unit GDIReg;

interface

uses
  Classes;

procedure Register;

implementation

uses
  GDICard;

procedure Register;
begin
  RegisterComponents('GDI+ Controls', [TGDICard]);
end;

end.
