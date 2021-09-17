unit GDICard;

interface


uses
  Vcl.Controls, Vcl.Graphics, Winapi.Messages, Winapi.Windows, Vcl.Forms, System.Classes, System.SysUtils, System.Math,
  Winapi.ActiveX, Gdi, GDICtrls, GDIBadge, GDIStyle, GDIImage, GDIText, GDITextBox;

type
  TGDICustomCard = class(TCustomCtrl)
  private
    FValidCache: Boolean;
    FCache: IGPBitmap;
    DisableCache: Boolean;
    FDown: Boolean;
    FBadges: TBadgeCollection;
    FTextBox: TGDITextBox;
    FData: Pointer;
    FStyle: TGDIStyle;
    FImage: TGDIImage;
    FTexts: TGDITextCollection;
    procedure Changed;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure InvalidateCache;
    procedure DoChanged(Sender: TObject);
    procedure SetTextBox(const Value: TGDITextBox);
    procedure SetBadges(const Value: TBadgeCollection);
    procedure SetStyle(const Value: TGDIStyle);
    procedure SetImage(const Value: TGDIImage);
    procedure SetTexts(const Value: TGDITextCollection);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    property Constraints;
    property Data: Pointer read FData write FData;

    property Badges: TBadgeCollection read FBadges write SetBadges;
    property Image: TGDIImage read FImage write SetImage;
    property Style: TGDIStyle read FStyle write SetStyle;
    property TextBox: TGDITextBox read FTextBox write SetTextBox;
    property Texts: TGDITextCollection read FTexts write SetTexts;
  end;

  TGDICard = class(TGDICustomCard)
  published
    property Align;
    property Anchors;
    property Badges;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Image;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Style;
    property TextBox;
    property Texts;
    property Visible;

    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  GDIUtils;

{ TGDICustomCard }

procedure TGDICustomCard.Changed;
begin
  FValidCache := false;
  Invalidate;
end;

procedure TGDICustomCard.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(CharCode, Caption) and CanFocus then
    begin
      FDown := True;
      Repaint;
      Click;
      FDown := false;
      Repaint;
      Result := 1;
    end
    else
      inherited;
end;

procedure TGDICustomCard.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Changed;
end;

procedure TGDICustomCard.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  Changed;
end;

procedure TGDICustomCard.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  Changed;
end;

procedure TGDICustomCard.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Changed;
end;

constructor TGDICustomCard.Create(AOwner: TComponent);
begin
  inherited;
  FImage := TGDIImage.Create(Self);
  FImage.OnChange := DoChanged;

  FStyle := TGDIStyle.Create(Self);
  FStyle.OnChange := DoChanged;

  FBadges := TBadgeCollection.Create(Self, TBadge);
  FBadges.OnChange := DoChanged;

  FTextBox := TGDITextBox.Create(Self);
  FTextBox.OnChange := DoChanged;

  FTexts := TGDITextCollection.Create(Self, TGDIText);
  FTexts.OnChange := DoChanged;

  DoubleBuffered := True;
  Constraints.MinHeight := 1;
  Constraints.MinWidth := 1;
  DisableCache := True;
  Width := 213;
  Height := 104;
  DisableCache := false;
  Font.Color := clWhite;
  Font.Name := 'Arial';
  Font.Style := [fsBold];
  FDown := false;
  FCache := TGPBitmap.Create(Width, Height, PixelFormat32bppARGB);
end;

destructor TGDICustomCard.Destroy;
begin
  FTextBox.Free;
  FBadges.Free;
  FStyle.Free;
  FImage.Free;
  FTexts.Free;
  inherited;
end;

procedure TGDICustomCard.InvalidateCache;
begin
  if not HandleAllocated then
    exit;

  if DisableCache then
    exit;

  FCache := TGPBitmap.Create(Width, Height);
  FValidCache := false;
end;

procedure TGDICustomCard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SetBounds(Left + 1, Top + 1, Width - 2, Height - 2);
  FDown := True;
  Changed;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TGDICustomCard.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SetBounds(Left - 1, Top - 1, Width + 2, Height + 2);
  FDown := false;
  Changed;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TGDICustomCard.Paint;

  procedure BeginPaint;
  var
    CR: TRect;
    rgn1: HRGN;
    i: Integer;
    p: TPoint;
  begin
    CR := ClientRect;
    rgn1 := CreateRectRgn(CR.Left, CR.Top, CR.Right, CR.Bottom);
    try
      SelectClipRgn(Canvas.Handle, rgn1);

      i := SaveDC(Canvas.Handle);
      p := ClientOrigin;
      Winapi.Windows.ScreenToClient(Parent.Handle, p);
      p.X := -p.X;
      p.Y := -p.Y;
      MoveWindowOrg(Canvas.Handle, p.X, p.Y);

      SendMessage(Parent.Handle, WM_ERASEBKGND, Canvas.Handle, 0);
      SendMessage(Parent.Handle, WM_PAINT, Canvas.Handle, 0);

      Parent.PaintCtrls(Canvas.Handle, nil);
      RestoreDC(Canvas.Handle, i);
      SelectClipRgn(Canvas.Handle, 0);
    finally
      DeleteObject(rgn1);
    end;
  end;

var
  GPGraphics: IGPGraphics;
begin
  BeginPaint;
  if not FValidCache then
  begin
    GPGraphics := TGPGraphics.Create(FCache);

    FStyle.Draw(GPGraphics);
    FBadges.Draw(GPGraphics);
    FTextBox.Draw(GPGraphics);
    FTexts.Draw(GPGraphics);
    FImage.Draw(GPGraphics);

    FValidCache := True;
  end;

  if FValidCache then
  begin
    GPGraphics := TGPGraphics.Create(Canvas.Handle);
    GPGraphics.DrawImage(FCache, 0, 0);
  end;
end;

procedure TGDICustomCard.DoChanged(Sender: TObject);
begin
  Changed;
end;

procedure TGDICustomCard.Resize;
begin
  inherited;
  InvalidateCache;
end;

procedure TGDICustomCard.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  InvalidateCache;
end;

procedure TGDICustomCard.SetImage(const Value: TGDIImage);
begin
  FImage.Assign(Value);
  Changed;
end;

procedure TGDICustomCard.SetStyle(const Value: TGDIStyle);
begin
  FStyle.Assign(Value);
end;

procedure TGDICustomCard.SetBadges(const Value: TBadgeCollection);
begin
  FBadges.Assign(Value);
end;

procedure TGDICustomCard.SetTextBox(const Value: TGDITextBox);
begin
  FTextBox.Assign(Value)
end;

procedure TGDICustomCard.SetTexts(const Value: TGDITextCollection);
begin
  FTexts.Assign(Value);
end;

procedure TGDICustomCard.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  if TabStop then
    Message.Result := DLGC_WANTALLKEYS or DLGC_WANTARROWS
  else
    Message.Result := 0;
end;

procedure TGDICustomCard.WMPaint(var Message: TWMPaint);
var
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  PS: TPaintStruct;
begin
  if not FDoubleBuffered or (Message.DC <> 0) then
  begin
    if not(csCustomPaint in ControlState) and (ControlCount = 0) then
      inherited
    else
      PaintHandler(Message);
  end
  else
  begin
    DC := GetDC(0);
    if DC <> 0 then
    begin
      MemBitmap := CreateCompatibleBitmap(DC, ClientRect.Right, ClientRect.Bottom);
      ReleaseDC(0, DC);
      MemDC := CreateCompatibleDC(0);
      OldBitmap := SelectObject(MemDC, MemBitmap);
      try
        DC := BeginPaint(Handle, PS);
        Perform(WM_ERASEBKGND, MemDC, MemDC);
        Message.DC := MemDC;
        WMPaint(Message);
        Message.DC := 0;
        BitBlt(DC, 0, 0, ClientRect.Right, ClientRect.Bottom, MemDC, 0, 0, SRCCOPY);
        EndPaint(Handle, PS);
      finally
        SelectObject(MemDC, OldBitmap);
        DeleteDC(MemDC);
        DeleteObject(MemBitmap);
      end;
    end;
  end;
end;

end.
