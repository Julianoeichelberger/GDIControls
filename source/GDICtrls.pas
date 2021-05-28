unit GDICtrls;

interface

uses
  System.Classes, Windows, SysUtils, Messages, Graphics, Controls, GDI;

type
  TWinControlHelper = class helper for TWinControl
  public
    procedure PaintCtrls(DC: HDC; First: TControl);
  end;

  TCustomCtrl = class(TCustomControl)
  public
    property Font;
    property Color;
    property Canvas;
    property ParentColor;
  end;

implementation

{ TWinControlHelper }

procedure TWinControlHelper.PaintCtrls(DC: HDC; First: TControl);
begin
  PaintControls(DC, First);
end;

end.
