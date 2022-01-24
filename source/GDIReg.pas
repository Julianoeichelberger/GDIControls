unit GDIReg;

interface

uses
  Classes;

procedure Register;

implementation

uses
  GDICard, GDIButton;

procedure Register;
begin
  RegisterComponents('GDI+ Controls', [TGDICard, TGDIButton]);
end;

end.
