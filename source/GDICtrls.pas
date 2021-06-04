unit GDICtrls;

interface

uses
  System.Classes, Windows, SysUtils, Messages, Graphics, Controls, GDI;

type
  TGDIAlign = (
    gaCenter, gaCenterLeft, gaCenterRight, gaTop, gaTopLeft, gaTopRight, gaBotton, gaBottonLeft, gaBottonRight);

  TWinControlHelper = class helper for TWinControl
  public
    procedure PaintCtrls(DC: HDC; First: TControl);
  end;

  TFontHelper = class helper for TFont
    function toGPFont(const AHandle: HDC): IGPFont;
  end;

  TCustomCtrl = class(TCustomControl)
  public
    function GetPoint(const Align: TGDIAlign;
      const AHeight: Single = 0; const AWidth: Single = 0; const APadding: Single = 0): TGPPointF;
    property Font;
    property Color;
    property Canvas;
    property ParentColor;
  end;

  TGDIPersistent = class(TPersistent)
  private
    FOnChange: TNotifyEvent;
  protected
    procedure DoChange(Sender: TObject); virtual;
  public
    procedure Draw(GPGraphics: IGPGraphics); virtual;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TGDICollectionItem = class(TCollectionItem)
  protected
    function Control: TCustomCtrl;
    procedure DoChange(Sender: TObject); virtual;
    procedure Draw(GPGraphics: IGPGraphics); virtual;
  end;

  TGDICollection = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  public
    function Control: TCustomCtrl;

    procedure Draw(GPGraphics: IGPGraphics); virtual;
    procedure DoChange; virtual;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{ TWinControlHelper }

procedure TWinControlHelper.PaintCtrls(DC: HDC; First: TControl);
begin
  PaintControls(DC, First);
end;

{ TFontHelper }

function TFontHelper.toGPFont(const AHandle: HDC): IGPFont;
var
  LogFnt: TLogFont;
begin
  LogFnt := Default (LogFont);
  LogFnt.lfHeight := Self.Height;
  LogFnt.lfCharSet := Self.Charset;
  StrPLCopy(LogFnt.lfFaceName, Self.Name, High(LogFnt.lfFaceName));
  LogFnt.lfOrientation := Self.Orientation;
  LogFnt.lfWeight := 700;
  LogFnt.lfItalic := Integer(fsItalic in Self.Style);
  LogFnt.lfUnderline := Integer(fsUnderline in Self.Style);
  LogFnt.lfStrikeOut := Integer(fsStrikeOut in Self.Style);
  LogFnt.lfQuality := Ord(Self.Quality);

  Result := TGPFont.Create(AHandle, LogFnt);
end;

{ TCustomCtrl }

function TCustomCtrl.GetPoint(const Align: TGDIAlign;
  const AHeight: Single; const AWidth: Single; const APadding: Single): TGPPointF;
begin
  case Align of
    gaTop:
      begin
        Result.X := (Self.Width div 2);
        if AWidth > 0 then
          Result.X := (Self.Width div 2) - (AWidth / 2);

        Result.Y := APadding;
      end;
    gaTopLeft:
      begin
        Result.X := APadding;
        Result.Y := APadding;
      end;

    gaTopRight:
      begin
        Result.X := Self.Width - AWidth - APadding;
        Result.Y := APadding;
      end;

    gaCenterLeft:
      begin
        Result.X := APadding;

        Result.Y := (Self.Height div 2);
        if AWidth > 0 then
          Result.Y := (Self.Height div 2) - (AHeight / 2);
      end;

    gaCenterRight:
      begin
        Result.X := Self.Width - AWidth - APadding;

        Result.Y := (Self.Height div 2);
        if AWidth > 0 then
          Result.Y := (Self.Height div 2) - (AHeight / 2);
      end;

    gaBotton:
      begin
        Result.X := (Self.Width div 2);
        if AWidth > 0 then
          Result.X := (Self.Width div 2) - (AWidth / 2);

        Result.Y := Self.Height - AHeight - APadding;
      end;

    gaBottonLeft:
      begin
        Result.X := APadding;
        Result.Y := Self.Height - AHeight - APadding;
      end;

    gaBottonRight:
      begin
        Result.X := Self.Width - AWidth - APadding;
        Result.Y := Self.Height - AHeight - APadding;
      end
  else
    Result.X := (Self.Width div 2);
    if AWidth > 0 then
      Result.X := (Self.Width div 2) - (AWidth / 2);

    Result.Y := (Self.Height div 2);
    if AWidth > 0 then
      Result.Y := (Self.Height div 2) - (AHeight / 2);
  end;
end;

{ TGDIPersistent }

procedure TGDIPersistent.DoChange(Sender: TObject);
begin
  if Assigned(FOnChange) then
    OnChange(Sender);
end;

procedure TGDIPersistent.Draw(GPGraphics: IGPGraphics);
begin
  // virtual
end;

{ TGDICollectionItem }

function TGDICollectionItem.Control: TCustomCtrl;
begin
  Result := TGDICollection(Collection).Control;
end;

procedure TGDICollectionItem.DoChange(Sender: TObject);
begin
  if Assigned(TGDICollection(Collection).FOnChange) then
    TGDICollection(Collection).OnChange(Sender);
end;

procedure TGDICollectionItem.Draw(GPGraphics: IGPGraphics);
begin
  // virtual
end;

{ TGDICollection }

function TGDICollection.Control: TCustomCtrl;
begin
  Result := TCustomCtrl(GetOwner);
end;

procedure TGDICollection.DoChange;
var
  I: Integer;
begin
  for I := 0 to Pred(Self.Count) do
    TGDICollectionItem(Self.Items[I]).DoChange(Self.Items[I]);
end;

procedure TGDICollection.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  inherited;
  if Action = cnRemoved then
    DoChange;
end;

procedure TGDICollection.Draw(GPGraphics: IGPGraphics);
var
  I: Integer;
begin
  for I := 0 to Pred(Self.Count) do
    TGDICollectionItem(Self.Items[I]).Draw(GPGraphics);
end;

end.
