unit frxComponents;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, Vcl.Graphics, frxClass,
  frxDsgnIntf, frxRes,
  frxDesgn,uRTMLLabel;

type
  TfrxRTMLLabel = class(TRTMLLabel)

  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
  private

    procedure Draw(Canvas: TCanvas; ScaleX, ScaleY, OffsetX, OffsetY: Extended);Override;
    class function GetDescription: string; static;

  published

    property Memo;

  end;


implementation


constructor TfrxRTMLLabel.Create(AOwner: TComponent);
begin
  inherited;

end;

destructor TfrxRTMLLabel.Destroy;
begin

  inherited;
end;

procedure TfrxRTMLLabel.Draw(Canvas: TCanvas;
  ScaleX, ScaleY, OffsetX, OffsetY: Extended);
begin
    Text := Memo.Text;

    if ParseToRTML then
      AnalyzeCode
    else
      RepaintLabel;
  //inherited;
end;

class function TfrxRTMLLabel.GetDescription: string;
begin
  result := 'RTML Label ';
end;

var
  Bmp: TBitmap;

initialization

Bmp := TBitmap.Create;
Bmp.LoadFromFile('G:\MyWork_FL\Delphi\2022\VCL  Add new component to FR\FR_RTML_Component\FR RTML Component\frxRTMLLabel.bmp');//
//Bmp.LoadFromResourceName(hInstance, 'frxRTMLLabel');
frxObjects.RegisterObject(TfrxRTMLLabel, Bmp);

finalization

frxObjects.Unregister(TfrxRTMLLabel);
Bmp.Free;

end.

