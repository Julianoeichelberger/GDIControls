unit GDIUtils;

interface

uses
  Graphics, Windows, SysUtils, GDI;

function MakeColor(a, R, G, B: Byte): UInt32; overload;
function MakeColor(a: Byte; Color: TColor): UInt32; overload;
function ColorToGPColor(AColor: TColor; AOpacity: word = 255): TGPColor;

implementation

function MakeColor(a, R, G, B: Byte): UInt32; overload;
const
  AlphaShift = 24;
  RedShift = 16;
  GreenShift = 8;
  BlueShift = 0;
begin
  Result := ((DWORD(B) shl BlueShift) or (DWORD(G) shl GreenShift) or (DWORD(R) shl RedShift) or (DWORD(a) shl AlphaShift));
end;

function MakeColor(a: Byte; Color: TColor): UInt32; overload;
var
  RGB: DWORD;
begin
  RGB := ColorToRGB(Color);
  Result := MakeColor(a, (RGB and $FF), (RGB and $FF00) shr 8, (RGB and $FF0000) shr 16);
end;

function ColorToGPColor(AColor: TColor; AOpacity: word): TGPColor;
begin
  Result.InitializeFromColorRef(AColor);
  Result.Alpha := AOpacity;
end;

end.
