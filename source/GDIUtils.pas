unit GDIUtils;

interface

uses
  Graphics, Windows, SysUtils, GDI;

type
  TGPFontHelper = class helper for TGPFont
    class function CreateByFont(const AHandle: HDC; const AFont: TFont): IGPFont;
  end;

function MakeColor(a, R, G, B: Byte): UInt32; overload;
function MakeColor(a: Byte; Color: TColor): UInt32; overload;

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

{ TGPFontHelper }

class function TGPFontHelper.CreateByFont(const AHandle: HDC; const AFont: TFont): IGPFont;
var
  LogFnt: TLogFont;
begin
  LogFnt := Default (LogFont);
  LogFnt.lfHeight := AFont.Height;
  LogFnt.lfCharSet := AFont.Charset;
  StrPLCopy(LogFnt.lfFaceName, AFont.Name, High(LogFnt.lfFaceName));
  LogFnt.lfOrientation := AFont.Orientation;
  LogFnt.lfWeight := 700;
  LogFnt.lfItalic := Integer(fsItalic in AFont.Style);
  LogFnt.lfUnderline := Integer(fsUnderline in AFont.Style);
  LogFnt.lfStrikeOut := Integer(fsStrikeOut in AFont.Style);
  LogFnt.lfQuality := Ord(AFont.Quality);

  Result := TGPFont.Create(AHandle, LogFnt);
end;

end.
