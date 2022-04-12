unit uRTMLLabel;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types,FMX.Graphics, FMX.StdCtrls, FMX.Objects,FMX.Surfaces,
  System.IOUtils,System.JSON,System.Math.Vectors, System.Math,
  frxClass,system.widestrings;

type
  TTokenKind = (tkUnknown, tkOpenTag, tkOpenFinalTag, tkCloseTag, tkSymbol, tkIdentifier, tkValue, tkText, tkComment, tkNewLine);
  TNodeType = (ntNone, ntTag, ntNewLine, ntImage, ntText);
  TCtrlType = (ctNone, ctText, ctNewLine, ctImage);
  TVerticalAlign = (vaTop, vaMiddle, vaBottom);

  PTreeNode  = ^RTreeNode;
  PToken     = ^RToken;
  PAttribute = ^RAttribute;
  RTreeNode = record
    Parent:      PTreeNode;
    First, Last: PTreeNode;
    Prev,  Next: PTreeNode;
    Token:       PToken;
    NodeType:    TNodeType;
    Text:        string;
    Attributes:  TList;
    TextGroup:   integer;
    Width,
    Height:      Single;
  end;

  RAttribute = record
    Attribute,
    Value:      string;
    TokenAttr,
    TokenValue: PToken;
  end;

  RToken = record
    Token:      string;
    RawToken:   string;
    UpperToken: string;
    TagName:    string;
    Pos:        integer;
    Line:       integer;
    Col:        integer;
    Len:        integer;
    RawLen:     integer;
    TokenKind:  TTokenKind;
  end;

  RAttributes = record
    FontFamily:    string;
    FontSize:      integer;
    FontBold:      boolean;
    FontItalic:    boolean;
    FontUnderline: boolean;
    FontStrike:    boolean;
    FontSup:       boolean;
    FontSub:       boolean;
    Color:         TAlphaColor;
    BackColor:     TAlphaColor;
    Opacity:       Single;
    RotationAngle: Single;
    Shadow:        boolean;
    ShadowOffsetX: Single;
    ShadowOffsetY: Single;
    ShadowColor:   TAlphaColor;
    ShadowOpacity: Single;
    BaseLine:      Single;
    TextAlign:     TTextAlign;
    LeftMargin:    Single;
    RightMargin:   Single;
    LineSpacing:   Single;
  end;

  PCtrlAttributes = ^RCtrlAttributes;
  RCtrlAttributes = record
    Attributes:    RAttributes;
    Top, Left,
    Height, Width: integer;
    CtrlType:      TCtrlType;
    Node:          PTreeNode;
    Text:          string;
    Image:         TBitmap;
  end;

  PRowItem = ^RRowItem;
  RRowItem = record
    Text:       string;
    IsImage:    boolean;
    Width,
    Height:     Single;
    TextGroup:  integer;
    Attributes: RAttributes;
    Ctrl:       PCtrlAttributes;
  end;

  PRowInfo = ^RRowInfo;
  RRowInfo = record
    MaxWidth,
    RemainingWidth,
    UsedWidth,
    Height:          Single;
    Items:           TList;
    Align:           TTextAlign;
    LeftMargin,
    RightMargin,
    LineSpacing:     Single;
  end;

  ArrString = array of string;

  TRTMLParser = class
  private
    FTokenList: TList;
    FRoot:      PTreeNode;
    FSource:    string;
    procedure SetSource (Value: string);
    function NewToken: PToken;
    function NewTreeNode: PTreeNode;
    function NewAttribute: PAttribute;
    procedure ClearAttributes (Node: PTreeNode);
    procedure AddChild (Parent, Child: PTreeNode);
    procedure ClearTokenList;
    procedure ClearTree;
    procedure ExtractTokens;
    procedure BuildTree;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Run;
    function ReplaceJSONVars (Text, JSON: string): string;
    property Source: string read FSource write SetSource;
    property Root: PTreeNode read FRoot;
    property TokenList: TList read FTokenList;
  end;

  TRTMLSettings = class
  private
    FMargins:     TBounds;
    FLineSpacing: Single;
    FOnChange:    TNotifyEvent;
    procedure SetLineSpacing (Value: Single);
    procedure OnChangeMargins (Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Margins: TBounds read FMargins write FMargins;
    property LineSpacing: Single read FLineSpacing write SetLineSpacing;
  end;

  TTextSettings = class
  private
    FFont: TFont;
    FHorzAlign: TTextAlign;
    FVertAlign: TTextAlign;
    FWordWrap: Boolean;
    FFontColor: TAlphaColor;
    FOnChanged: TNotifyEvent;
    FTrimming: TTextTrimming;
    procedure SetHorzAlign (Value: TTextAlign);
    procedure SetVertAlign (Value: TTextAlign);
    procedure SetWordWrap (Value: boolean);
    procedure SetFontColor (Value: TAlphaColor);
    procedure SetTriming (Value: TTextTrimming);
    procedure Change;
    procedure OnFontChanged (Sender: TObject);
  protected
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Font: TFont read FFont write FFont;
    property HorzAlign: TTextAlign read FHorzAlign write SetHorzAlign;
    property VertAlign: TTextAlign read FVertAlign write SetVertAlign;
    property WordWrap: boolean read FWordWrap write SetWordWrap;
    property FontColor: TAlphaColor read FFontColor write SetFontColor;
    property Trimming: TTextTrimming read FTrimming write SetTriming;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TRTMLLabel = class ({TImage}{frxClass.TfrxPictureView}frxClass.TfrxMemoView)
  private
    FBMP : TBitMap;
    FParser:          TRTMLParser;
    CtrlAttrib:       TList;
    Rows:             TList;
    FAutoSize:        boolean;
    FText:            Widestring;
//    FMemo: {TStringList}TWideStrings;
    FJSON:            string;
    FParseToRTML:     boolean;
    FTextSettings:    TTextSettings;
    FRTMLSettings:    TRTMLSettings;
    FDefaultFontName: string;
    FDefaultFontSize: Single;

    procedure PictureChanged(Sender: TObject);
    function GetText: Widestring;
    procedure SetText (Value: Widestring);
    function GetJSON: string;
    procedure SetJSON (Value: string);
    procedure SetParseToRTML (Value: boolean);
    procedure SetAutoSize (Value: boolean);
    procedure OnChangeTextSettings (Sender: TObject);
    procedure OnChangeRotationCenter (Sender: TObject);
    procedure OnChangeRTMLSettings (Sender: TObject);
    function Trim (s: string): string;
    function CountWords (s: string): integer;
    function GetWordSize (S: string; Start: integer): integer;
    function GetNextWord (S: string; Start: integer = 1): integer;
    function GetLastWordChar (S: string; Start: integer = 0): integer;
    function GetStartWord (S: string; Last: integer): integer;
    procedure SplitWord (Text: string; MaxWidth: Single; var List: ArrString; UsedCanvas: TCanvas);
    procedure SplitText (Text: string; MaxWidth, RemainingWidth: Single; var List: ArrString; UsedCanvas: TCanvas; var ForceNewLine: boolean);
    function NewPCtrlAttributes: PCtrlAttributes;
    function NewPRowInfo: PRowInfo;
    function NewPRowItem: PRowItem;
    procedure ClearCtrlAttrib;
    procedure ClearRows;
    procedure GenerateCtrlAttrib;
    procedure GenerateRows (UsedCanvas: TCanvas);
    procedure RepaintAsRTML;
    procedure RepaintAsLabel;
    procedure ReadDefaultAttribute (var Attr: RAttributes);
    procedure CopyAttributes (Source: RAttributes; var Target: RAttributes);
    procedure SetFontAttributes (Attrib: RAttributes; Font: TFont);
    function RemoveQuotes (s: string): string;
    function StringToColor (s: string): TAlphaColor;
    procedure DrawRotatedText(Canvas: TCanvas; const P: TPointF; RadAngle: Single; const S: String; HTextAlign, VTextAlign: TTextAlign);
    procedure AssignBitmapToPicture(pBmp: TBitMap);
//    procedure SetMemo(const Value: {TStringList}TWideStrings);
//    procedure LinesChanged(Sender: TObject);
  protected
//    procedure Resize; override;
  public
    constructor Create (AOwner: TComponent); override;
    procedure AfterConstruction; override;
    destructor Destroy; override;
    procedure AnalyzeCode;
    procedure RepaintLabel;
    property Parser: TRTMLParser read FParser;
    property JSON: string read GetJSON write SetJSON;
//    property Memo: {TStringList}TWideStrings read FMemo write SetMemo;

  published

    property Memo;
    property Text: Widestring read GetText write SetText;
    property ParseToRTML: boolean read FParseToRTML write SetParseToRTML;
    property AutoSize: boolean read FAutoSize write SetAutoSize;
    property TextSettings: TTextSettings read FTextSettings write FTextSettings;
    property RTMLSettings: TRTMLSettings read FRTMLSettings write FRTMLSettings;
  end;

implementation

const
  SingleTags = '|IMG|IMAGE|';
  Spaces     = [' ', #9, #10, #13];

{$region 'THTMLParser'}
constructor TRTMLParser.Create;
begin
  FTokenList := TList.Create;
  FSource    := '';
  FRoot      := nil;
end;

destructor TRTMLParser.Destroy;
begin
  FSource := '';
  Clear;
  FTokenList.Free;

  inherited;
end;

procedure TRTMLParser.SetSource (Value: string);
begin
  if Value <> FSource then
  begin
    FSource := Value;
    Run;
  end;
end;

function TRTMLParser.NewToken: PToken;
begin
  New (result);
  result^.Token      := '';
  result^.RawToken   := '';
  result^.UpperToken := '';
  result^.TagName    := '';
  result^.Pos        := 0;
  result^.Line       := 0;
  result^.Col        := 0;
  result^.Len        := 0;
  result^.RawLen     := 0;
  result^.TokenKind  := tkUnknown;
end;

function TRTMLParser.NewTreeNode: PTreeNode;
begin
  New (result);
  result^.Parent     := nil;
  result^.First      := nil;
  result^.Last       := nil;
  result^.Prev       := nil;
  result^.Next       := nil;
  result^.Token      := nil;
  result^.NodeType   := ntNone;
  result^.Text       := '';
  result^.Attributes := TList.Create;
  result^.TextGroup  := -1;
  result^.Width      := 0;
  result^.Height     := 0;
end;

function TRTMLParser.NewAttribute: PAttribute;
begin
  New (result);
  result^.Attribute  := '';
  result^.Value      := '';
  result^.TokenAttr  := nil;
  result^.TokenValue := nil;
end;

procedure TRTMLParser.ClearTokenList;
var
  Token: PToken;
  i: integer;
begin
  for i := 0 to FTokenList.Count - 1 do
  begin
    Token             := PToken (FTokenList[i]);
    FTokenList [i]    := nil;
    Token^.Token      := '';
    Token^.RawToken   := '';
    Token^.UpperToken := '';
    Dispose (Token);
  end;
  FTokenList.Clear;
end;

procedure TRTMLParser.ClearAttributes (Node: PTreeNode);
var
  i: integer;
  Attrib: PAttribute;
begin
  for i := 0 to Node^.Attributes.Count - 1 do
  begin
    Attrib               := PAttribute (Node^.Attributes [i]);
    Node^.Attributes [i] := nil;
    Attrib^.Attribute    := '';
    Attrib^.Value        := '';
    Dispose (Attrib);
  end;
  Node^.Attributes.Clear;
  Node^.Attributes.Free;
end;


procedure TRTMLParser.ClearTree;

  procedure DeleteTree (var Node: PTreeNode);
  var
    Child, Next: PTreeNode;
  begin
    if not Assigned (Node) then exit;

    Child := Node^.First;
    while Assigned (Child) do
    begin
      Next := Child^.Next;
      DeleteTree (Child);
      Child := Next;
    end;

    Node^.Text := '';
    ClearAttributes(Node);
    Dispose (Node);
    Node := nil;
  end;
begin
  DeleteTree (FRoot);
end;

procedure TRTMLParser.Clear;
begin
  ClearTree;
  ClearTokenList;
end;

procedure TRTMLParser.AddChild (Parent, Child: PTreeNode);
begin
  if not Assigned (Parent^.First) then
    Parent^.First := Child;

  if Assigned (Parent^.Last) then
  begin
    Child^.Prev        := Parent^.Last;
    Parent^.Last^.Next := Child;
  end;
  Parent^.Last  := Child;
  Child^.Parent := Parent;
end;

procedure TRTMLParser.ExtractTokens;
var
  Idx, n, Line, Col: integer;
  Entity:          string;
  Token:           PToken;
  GettingTagName:  boolean;
  inTag:           boolean;

  function EOF: boolean;
  begin
    {$IFDEF MSWINDOWS}
    result := Idx >  Length (Source);
    {$ENDIF}
    {$IFDEF ANDROID}
    result := Idx >= Length (Source);
    {$ENDIF}
  end;

  function GetChar: char;
  begin
    result := Source [Idx];
  end;

  function GetCharAndMove: char;
  begin
    result := Source [Idx];
    Inc (Idx);

    case Source [Idx] of
      #10: Inc (Line);
      #13: Col := 1;
      else Inc (Col);
    end;
  end;

  procedure NextChar;
  begin
    Inc (Idx);

    case Source [Idx] of
      #10: Inc (Line);
      #13: Col := 1;
      else Inc (Col);
    end;
  end;

  function GetNextNChars (NumChars: integer): string;
  var
    ni: integer;
  begin
    result := Source [Idx];
    Dec (NumChars);

    for ni := 1 to NumChars do
      if (Idx + ni) <= Length (Source) then
        result := result + Source [Idx + ni];
  end;

begin
  Clear;

  {$IFDEF MSWINDOWS}
  Idx       := 1;
  {$ENDIF}
  {$IFDEF ANDROID}
  Idx       := 0;
  {$ENDIF}
  Line      := 1;
  Col       := 1;
  inTag     := False;
  while not EOF do
  begin
    case GetChar of
      {#10, }#13: begin
        Token            := NewToken;
        Token^.Pos       := Idx;
        Token^.Line      := Line;
        Token^.Col       := Col;
        Token^.TokenKind := tkNewLine;
        FTokenList.Add(Token);
        NextChar;
        NextChar;
      end;
      '<': begin
          Token       := NewToken;
          Token^.Pos  := Idx;
          Token^.Line := Line;
          Token^.Col  := Col;
          if GetNextNChars (2) = '</' then
          begin
            inTag            := True;
            Token^.Token     := '</';
            Token^.TokenKind := tkOpenFinalTag;
            NextChar;
            NextChar;
          end
          else if GetNextNChars (4) = '<!--' then
          begin
            Token^.Token := GetCharAndMove + GetCharAndMove + GetCharAndMove + GetCharAndMove;
            while not EOF and (GetNextNChars (3) <> '-->') do
              Token^.Token := Token^.Token + GetCharAndMove;

            if not EOF and (GetNextNChars (3) = '-->') then
              Token^.Token   := Token^.Token + GetCharAndMove + GetCharAndMove + GetCharAndMove;

            Token^.TokenKind := tkComment;
          end
          else
          begin
            inTag            := True;
            Token^.Token     := GetCharAndMove;
            Token^.TokenKind := tkOpenTag;
          end;
          Token^.RawToken   := Token^.Token;
          Token^.UpperToken := UpperCase (Token^.Token);
          Token^.Len        := Length (Token^.Token);
          Token^.RawLen     := Token^.Len;
          FTokenList.Add(Token);
      end;
      '>', ':': begin
        Token       := NewToken;
        Token^.Pos  := Idx;
        Token^.Line := Line;
        Token^.Col  := Col;
        if inTag and (GetChar = '>') then
        begin
          inTag := False;
          Token^.TokenKind := tkCloseTag;
        end
        else
          Token^.TokenKind := tkSymbol;

        Token^.Token      := GetCharAndMove;
        Token^.RawToken   := Token^.Token;
        Token^.UpperToken := UpperCase (Token^.Token);
        Token^.Len        := Length (Token^.Token);
        Token^.RawLen     := Token^.Len;
        FTokenList.Add(Token);
      end;
      else begin
        Token       := NewToken;
        Token^.Pos  := Idx;
        Token^.Line := Line;
        Token^.Col  := Col;
        if inTag then
        begin
            case GetChar of
              'A'..'Z',
              'a'..'z': begin
                while not EOF and (GetChar in ['A'..'Z', 'a'..'z', '0'..'9']) do
                  Token^.Token := Token^.Token + GetCharAndMove;

                Token^.TokenKind  := tkIdentifier;
                Token^.RawToken   := Token^.Token;
                Token^.UpperToken := UpperCase (Token^.Token);
                Token^.Len        := Length (Token^.Token);
                Token^.RawLen     := Token^.Len;
                FTokenList.Add(Token);
              end;
              '"': begin
                Token^.Token := GetCharAndMove;
                while not EOF and (GetChar <> '"') do
                  Token^.Token := Token^.Token + GetCharAndMove;

                if not EOF and (GetChar = '"') then
                  Token^.Token := Token^.Token + GetCharAndMove;

                Token^.TokenKind  := tkValue;
                Token^.RawToken   := Token^.Token;
                Token^.UpperToken := UpperCase (Token^.Token);
                Token^.Len        := Length (Token^.Token);
                Token^.RawLen     := Token^.Len;
                FTokenList.Add(Token);
              end;
              else NextChar;
            end;
        end
        else
        begin
          Token^.Pos       := Idx;
          Token^.Line      := Line;
          Token^.Col       := Col;
          Token^.TokenKind := tkText;
          while not EOF and (GetChar <> '<') do
          begin
            if (GetChar = #13) and (GetNextNChars (2) = sLineBreak) then
            begin
              Token^.UpperToken := UpperCase (Token^.Token);
              Token^.Len        := Length (Token^.Token);
              Token^.RawLen     := Length (Token^.RawToken);
              FTokenList.Add(Token);

              Token            := NewToken;
              Token^.Pos       := Idx;
              Token^.Line      := Line;
              Token^.Col       := Col;
              Token^.TokenKind := tkNewLine;
              FTokenList.Add(Token);
              NextChar;
              NextChar;

              if not EOF and (GetChar <> '<') then
              begin
                Token            := NewToken;
                Token^.Pos       := Idx;
                Token^.Line      := Line;
                Token^.Col       := Col;
                Token^.TokenKind := tkText;
              end;
            end
            else if GetChar = '&' then
            begin
              Token^.RawToken := Token^.RawToken + GetChar;
              Entity          := '';
              NextChar;
              while not EOF and (GetChar <> ';') do
              begin
                Token^.RawToken := Token^.RawToken + GetChar;
                Entity          := Entity + GetCharAndMove;
              end;

              if not EOF and (GetChar = ';') then
              begin
                Token^.RawToken := Token^.RawToken + GetChar;
                NextChar;

                if      UpperCase (Entity) = 'AMP' then Token^.Token := Token^.Token + '&'
                else if UpperCase (Entity) = 'GT'  then Token^.Token := Token^.Token + '>'
                else if UpperCase (Entity) = 'LT'  then Token^.Token := Token^.Token + '<'
                else if Not Entity.IsEmpty and (Entity [1] = '#') then
                begin
                  Delete (Entity, 1, 1);
                  if TryStrToInt (Entity, n) then
                  begin
                    Token^.Token := Token^.Token + Chr (n);
                  end;
                end;
              end;
            end
            else
            begin
              Token^.RawToken := Token^.RawToken + GetChar;
              Token^.Token    := Token^.Token    + GetCharAndMove;
            end;
          end;

          if Token^.TokenKind <> tkNewLine then
          begin
            Token^.UpperToken := UpperCase (Token^.Token);
            Token^.Len        := Length (Token^.Token);
            Token^.RawLen     := Length (Token^.RawToken);
            FTokenList.Add(Token);
          end;
        end;
      end;
    end;
  end;
end;

procedure TRTMLParser.BuildTree;
var
  Idx, TextGroup: integer;
  Token: PToken;
  Node, CurrentParent, Item: PTreeNode;
  Attrib: PAttribute;
  inTag: boolean;
  s: string;

  function GetCurrentToken: PToken;
  begin
    result := nil;
    if Idx < FTokenList.Count then
      result := PToken (FTokenList [Idx]);
  end;

  function GetCurrentTokenAndMove: PToken;
  begin
    result := nil;
    if Idx < FTokenList.Count then
      result := PToken (FTokenList [Idx]);

    Inc (Idx);
  end;

  procedure MoveNext;
  begin
    Inc (Idx);
  end;

  function EOF: boolean;
  begin
    result := Idx >= FTokenList.Count;
  end;

begin
  ClearTree;
  TextGroup   := 0;
  FRoot         := NewTreeNode;
  CurrentParent := FRoot;
  inTag         := False;
  Idx           := 0;
  while not EOF do
  begin
    Token := GetCurrentTokenAndMove;
    if not Assigned (Token) then break;

    case Token^.TokenKind of
      tkNewLine: begin
        if Assigned (Token) then
        begin
          Node           := NewTreeNode;
          Node^.Token    := Token;
          Node^.NodeType := ntNewLine;
          AddChild(CurrentParent, Node);
        end;
      end;
      tkOpenTag: begin
        Token := GetCurrentTokenAndMove;
        if Assigned (Token) and (Token^.TokenKind = tkIdentifier) then
        begin
          Node         := NewTreeNode;
          Node^.Token  := Token;
          Node^.Text   := Token^.UpperToken;
          AddChild(CurrentParent, Node);

          Node^.NodeType := ntTag;
          if (Token^.UpperToken = 'IMG') or (Token^.UpperToken = 'IMAGE') then
            Node^.NodeType := ntImage
          else
            CurrentParent := Node;

          if Token^.UpperToken = 'ALIGN' then
          begin
            Node^.TextGroup := TextGroup;
            Inc (TextGroup);
          end;

          while not EOF and (GetCurrentToken^.TokenKind = tkSymbol) and (GetCurrentToken^.Token = ':') do
          begin
            MoveNext;
            while not EOF and (GetCurrentToken^.TokenKind in [tkComment, tkNewLine]) do
              MoveNext;

            if not EOF and (GetCurrentToken^.TokenKind in [tkIdentifier, tkValue]) then
            begin
              Attrib             := NewAttribute;
              Attrib^.TokenValue := GetCurrentToken;
              Attrib^.Value      := GetCurrentTokenAndMove^.Token;
              Node^.Attributes.Add(Attrib);
            end;
          end;


{          while not EOF and (GetCurrentToken^.TokenKind = tkIdentifier) do
          begin
            Attrib            := NewAttribute;
            Attrib^.TokenAttr := GetCurrentToken;
            Attrib^.Attribute := GetCurrentTokenAndMove^.UpperToken;

            if not EOF and (GetCurrentToken^.TokenKind = tkSymbol) and (GetCurrentToken^.Token = ':') then
            begin
              MoveNext;

              if not EOF and (GetCurrentToken^.TokenKind in [tkIdentifier, tkValue]) then
              begin
                Attrib^.TokenValue := GetCurrentToken;
                Attrib^.Value      := GetCurrentTokenAndMove^.Token;
              end;
            end;

            Node^.Attributes.Add(Attrib);
          end;}
        end;

        if not EOF and (GetCurrentToken^.TokenKind = tkCloseTag) then
          MoveNext;
      end;
      tkOpenFinalTag: begin
        Token := GetCurrentTokenAndMove;
        if not EOF and Assigned (Node) and Assigned (Token) and (Token^.TokenKind = tkIdentifier) then
        begin
          Item := Node;
          while Assigned (Item) and Assigned (Item^.Token) and ((Item^.Token^.UpperToken <> Token^.UpperToken) or (Item^.NodeType <> ntTag)) do
            Item := Item^.Parent;

          if Assigned (Item) and Assigned (Item.Parent) and Assigned (Item^.Token) and (Item^.Token^.UpperToken = Token^.UpperToken) and (Item^.NodeType = ntTag) then
            CurrentParent := Item.Parent;
        end;

        if not EOF and (GetCurrentToken^.TokenKind = tkCloseTag) then
          MoveNext;
      end;
      tkText: begin
        Node           := NewTreeNode;
        Node^.Token    := Token;
        Node^.Text     := Token^.Token;
        Node^.Parent   := CurrentParent;
        Node^.NodeType := ntText;
        AddChild(CurrentParent, Node);
      end;
    end;
  end;
end;

procedure TRTMLParser.Run;
begin
  ExtractTokens;
  BuildTree;
end;

function TRTMLParser.ReplaceJSONVars (Text, JSON: string): string;
var
  v, value:  string;
  Idx,
  Idx2:      integer;
  Found:     boolean;
  JSONValue: TJSONValue;
begin
  result    := Text;
  Idx       := 1;
  JSONValue := TJSONObject.ParseJSONValue(JSON);
  repeat
    Found := False;
    Idx   := Pos ('{:', result, Idx);
    if Idx > 0 then
    begin
      Idx2 := Pos ('}', result, Idx + 1);

      if Idx2 > 0 then
      begin
        v := Copy (result, Idx + 2, Idx2 - Idx - 2);
        if Trim (v) <> '' then
        begin
          value := '';
          if JSONValue.FindValue(v) <> nil then
            value := JSONValue.GetValue<string>(v);
          result := Copy (result, 1, Idx - 1) + value + Copy (result, Idx2 + 1, Length (result));
          Found  := True;
        end;
      end;
    end;
  until not Found;
end;
{$endregion}

{$region 'TRTMLSettings'}
constructor TRTMLSettings.Create;
begin
  FMargins          := TBounds.Create (TRectF.Create (3, 3, 3, 3));
  FMargins.OnChange := OnChangeMargins;
  FLineSpacing      := 3;
  FOnChange         := nil;
end;

destructor TRTMLSettings.Destroy;
begin
  FMargins.Free;

  inherited Destroy;
end;

procedure TRTMLSettings.SetLineSpacing (Value: Single);
begin
  if FLineSpacing <> Value then
  begin
    FLineSpacing := Value;

    if Assigned (FOnChange) then
      FOnChange (Self);
  end;
end;

procedure TRTMLSettings.OnChangeMargins (Sender: TObject);
begin
  if Assigned (FOnChange) then
    FOnChange (Self);
end;
{$endregion}

{$region 'TTextSettings'}
constructor TTextSettings.Create;
begin
  FFont           := TFont.Create;
  FFont.OnChanged := OnFontChanged;
  FHorzAlign      := TTextAlign.Leading;
  FVertAlign      := TTextAlign.Center;
  FWordWrap       := True;
  FFontColor      := TAlphaColors.Black;
  FOnChanged      := nil;
  FTrimming       := TTextTrimming.Character;
end;

destructor TTextSettings.Destroy;
begin
  FFont.Free;

  inherited Destroy;
end;

procedure TTextSettings.SetHorzAlign (Value: TTextAlign);
begin
  if FHorzAlign <> Value then
  begin
    FHorzAlign := Value;
    Change;
  end;
end;

procedure TTextSettings.SetVertAlign (Value: TTextAlign);
begin
  if FVertAlign <> Value then
  begin
    FVertAlign := Value;
    Change;
  end;
end;

procedure TTextSettings.SetWordWrap (Value: boolean);
begin
  if FWordWrap <> Value then
  begin
    FWordWrap := Value;
    Change;
  end;
end;

procedure TTextSettings.SetFontColor (Value: TAlphaColor);
begin
  if FFontColor <> Value then
  begin
    FFontColor := Value;
    Change;
  end;
end;

procedure TTextSettings.SetTriming (Value: TTextTrimming);
begin
  if FTrimming <> Value then
  begin
    FTrimming := Value;
    Change;
  end;
end;

procedure TTextSettings.Change;
begin
  if Assigned (FOnChanged) then
    FOnChanged (Self);
end;

procedure TTextSettings.OnFontChanged (Sender: TObject);
begin
  Change;
end;
{$endregion}


{$region 'TRTMLLabel'}
constructor TRTMLLabel.Create (AOwner: TComponent);
var
  tmpLabel: TLabel;
begin
  inherited Create (AOwner);
  FBMP := TBitMap.Create;
//  BeginUpdate;
  CtrlAttrib               := TList.Create;
  Rows                     := TList.Create;
  FParser                  := TRTMLParser.Create;
  FText                    := '';
  {$IFDEF Delphi10}
//  FMemo := TfrxWideStrings.Create;
{$ELSE}
//  FMemo := {TStringList}TWideStrings.Create;
//  TStringList(FMemo).OnChange := LinesChanged;
{$ENDIF}
  FJSON                    := '';
  Width                    := 120;
  Height                   := 17;
  FParseToRTML             := False;
  FAutoSize                := True;
  FTextSettings            := TTextSettings.Create;
  FRTMLSettings            := TRTMLSettings.Create;
  tmpLabel                 := TLabel.Create(Self);
  FDefaultFontName         := tmpLabel.Font.Family;
  FDefaultFontSize         := tmpLabel.Font.Size;
  tmpLabel.Free;
  FTextSettings.OnChanged  := OnChangeTextSettings;
  FRTMLSettings.FOnChange  := OnChangeRTMLSettings;
end;

procedure TRTMLLabel.AfterConstruction;
begin
  inherited AfterConstruction;
//  EndUpdate;
end;


destructor TRTMLLabel.Destroy;
begin
  ClearRows;
  ClearCtrlAttrib;
  FTextSettings.Free;
  FRTMLSettings.Free;
//  FMemo.Free;
  Rows.Free;
  FParser.Free;
  CtrlAttrib.Free;
  FBMP.Free;
  inherited Destroy;
end;
(*
procedure TRTMLLabel.Resize;
begin
  inherited;

//  if FUpdating > 0 then exit;

  if FParseToRTML then
    GenerateCtrlAttrib;

  RepaintLabel;
end;
 *)
function TRTMLLabel.GetText: Widestring;
begin
  result := FText;
end;

procedure TRTMLLabel.SetText (Value: Widestring);
begin
  if FText <> Value then
  begin
    FText := Value;

    if FParseToRTML then
      AnalyzeCode
    else
      RepaintLabel;
  end;
end;

(*
procedure TRTMLLabel.LinesChanged(Sender: TObject);
begin
  // Repaint, update or whatever you need to do.
  if FParseToRTML then
    AnalyzeCode
  else
    RepaintLabel;
end;

procedure TRTMLLabel.SetMemo(const Value: {TStringList}TWideStrings);
begin
  FMemo.Assign(Value);
  if FParseToRTML then
    AnalyzeCode
  else
    RepaintLabel;
end;
*)
function TRTMLLabel.GetJSON: string;
begin
  result := FJSON;
end;

procedure TRTMLLabel.SetJSON (Value: string);
begin
  if FJSON <> Value then
  begin
    FJSON := Value;

    AnalyzeCode;
  end;
end;

procedure TRTMLLabel.SetParseToRTML (Value: boolean);
begin
  if FParseToRTML <> Value then
  begin
    FParseToRTML := Value;

    if FParseToRTML then
      AnalyzeCode
    else
      RepaintLabel;
  end;
end;

procedure TRTMLLabel.SetAutoSize (Value: boolean);
begin
  if FAutoSize <> Value then
  begin
    FAutoSize := Value;

    if not ParseToRTML then
      RepaintLabel;
  end;
end;

procedure TRTMLLabel.OnChangeTextSettings (Sender: TObject);
begin
  RepaintLabel;
end;

procedure TRTMLLabel.PictureChanged(Sender: TObject);
begin
  inherited;
  if FParseToRTML then
    GenerateCtrlAttrib;

  RepaintLabel;
end;

procedure TRTMLLabel.OnChangeRotationCenter (Sender: TObject);
begin
  RepaintLabel;
end;

procedure TRTMLLabel.OnChangeRTMLSettings (Sender: TObject);
begin
  GenerateCtrlAttrib;
  RepaintLabel;
end;

function TRTMLLabel.Trim (s: string): string;
begin
  result := s;

  while (Length (result) > 0) and (result[1] in Spaces) do
    Delete (result, 1, 1);

  while (Length (result) > 0) and (result[Length (result)] in Spaces) do
    Delete (result, Length (result), 1);
end;

function TRTMLLabel.CountWords (s: string): integer;
var
  i: integer;
  inWord: boolean;
begin
  result := 0;
  inWord := False;
  for i := 1 to Length (s) do
  begin
    if not inWord and not (s [i] in Spaces) then
      Inc (result);

    inWord := not (s [i] in Spaces);
  end;
end;

function TRTMLLabel.GetNextWord (S: string; Start: integer = 1): integer;
var
  i: integer;
begin
  result := -1;
  if Start > Length (s) then exit;

  for i := Start to Length (S) do
    if not (s [i] in Spaces) then
    begin
      result := i;
      exit;
    end;
end;

function TRTMLLabel.GetWordSize (S: string; Start: integer): integer;
var
  i: integer;
begin
  result := 0;

  for i := Start to Length (s) do
  begin
    if s [i] in Spaces then exit;

    Inc (result);
  end;
end;

function TRTMLLabel.GetLastWordChar (S: string; Start: integer = 0): integer;
var
  i: integer;
begin
  result := -1;
  if Start = 0 then
    Start := Length (S);

  if (Start < 0) or (Start > Length (s)) then exit;

  for i := Start downto 1 do
    if not (s [i] in Spaces) then
    begin
      result := i;
      exit;
    end;
end;

function TRTMLLabel.GetStartWord (S: string; Last: integer): integer;
var
  i: integer;
begin
  result := Last;

  for i := Last - 1 downto 1 do
  begin
    if s [i] in Spaces then exit;

    Dec (result);
  end;
end;

procedure TRTMLLabel.SplitWord (Text: string; MaxWidth: Single; var List: ArrString; UsedCanvas: TCanvas);
var
  i: integer;
  s: string;
begin
  SetLength (List, 0);
  if UsedCanvas.TextWidth (Text) <= MaxWidth then
  begin
    SetLength (List, 1);
    List [0] := Text;
    exit;
  end;

  for i := Length (Text) - 1 downto 1 do
  begin
    s := Copy (Text, 1, i);

    if UsedCanvas.TextWidth (s) <= MaxWidth then
    begin
      SetLength (List, 2);
      List [0] := s;
      List [1] := Copy (Text, i + 1, Length (Text));
      exit;
    end;
  end;
end;

procedure TRTMLLabel.SplitText (Text: string; MaxWidth, RemainingWidth: Single; var List: ArrString; UsedCanvas: TCanvas; var ForceNewLine: boolean);
var
  Start, Len, Last, ZeroTimes: integer;
  s: string;
begin
  ForceNewLine := False;
  SetLength (List, 0);

  if UsedCanvas.TextWidth (Text) <= RemainingWidth then
  begin
    SetLength (List, 1);
    List [0] := Text;
    exit;
  end;

  if CountWords (Text) < 2 then
  begin
    SplitWord (Trim (Text), RemainingWidth, List, UsedCanvas);
    exit;
  end;

  Last      := 0;
  ZeroTimes := 1;
  repeat
    Last := GetLastWordChar(Text, Last);
    if Last > 0 then
    begin
      Start := GetStartWord(Text, Last);
      s     := Copy (Text, 1, Last);
      if UsedCanvas.TextWidth (s) <= RemainingWidth then
      begin
        SetLength (List, Length (List) + 1);
        List [Length (List) - 1] := s;
        Delete (Text, 1, Last);
        break;
      end
      else
        Last := Start - 1;
    end;

    if Last = 0 then
      Inc (ZeroTimes);
  until (Last <= 0) or (ZeroTimes > 1) or (Length (List) > 0) or (UsedCanvas.TextWidth (Text) <= RemainingWidth);

  ForceNewLine := (ZeroTimes > 1) or (Last <= 0);
  if not Text.IsEmpty then
  begin
    SetLength (List, Length (List) + 1);
    List [Length (List) - 1] := Text;
    ForceNewLine             := ForceNewLine or (UsedCanvas.TextWidth(Text) > RemainingWidth);
  end
end;

function TRTMLLabel.NewPCtrlAttributes: PCtrlAttributes;
begin
  New (result);
  ReadDefaultAttribute (result^.Attributes);
  result^.Top       := 0;
  result^.Left      := 0;
  result^.Height    := 0;
  result^.Width     := 0;
  result^.CtrlType  := ctNone;
  result^.Node      := nil;
  result^.Text      := '';
  result^.Image     := nil;
end;

function TRTMLLabel.NewPRowInfo: PRowInfo;
begin
  New (result);
  result^.MaxWidth       := Width - (RTMLSettings.Margins.Left + RTMLSettings.Margins.Right);
  result^.RemainingWidth := result^.MaxWidth;
  result^.UsedWidth      := 0;
  result^.Height         := 0;
  result^.Align          := TTextAlign.Leading;
  result^.Items          := TList.Create;
  result^.LeftMargin     := RTMLSettings.Margins.Left;
  result^.RightMargin    := RTMLSettings.Margins.Right;
  result^.LineSpacing    := RTMLSettings.LineSpacing;
end;

function TRTMLLabel.NewPRowItem: PRowItem;
begin
  New (result);
  result^.Text      := '';
  result^.IsImage   := False;
  result^.Width     := 0;
  result^.Height    := 0;
  result^.TextGroup := -1;
  result^.Ctrl      := nil;
  ReadDefaultAttribute(result^.Attributes);
end;

procedure TRTMLLabel.ClearCtrlAttrib;
var
  i:      integer;
  Attrib: PCtrlAttributes;
begin
  for i := 0 to CtrlAttrib.Count - 1 do
  begin
    Attrib                        := PCtrlAttributes (CtrlAttrib [i]);
    CtrlAttrib [i]                := nil;
    Attrib^.Attributes.FontFamily := '';

    if Assigned (Attrib) then
      Attrib^.Image.Free;

    Dispose (Attrib);
  end;
  CtrlAttrib.Clear;
end;

procedure TRTMLLabel.ClearRows;
var
  i, j: integer;
  Row:  PRowInfo;
  Item: PRowItem;
begin
  for i := 0 to Rows.Count - 1 do
  begin
    Row      := PRowInfo (Rows [i]);
    Rows [i] := nil;

    for j := 0 to Row^.Items.Count - 1 do
    begin
      Item                        := PRowItem (Row^.Items [j]);
      Row^.Items [j]              := nil;
      Item^.Text                  := '';
      Item^.Attributes.FontFamily := '';
      Dispose (Item);
    end;
    Row^.Items.Free;
    Dispose (Row);
  end;
  Rows.Clear;
end;

procedure TRTMLLabel.ReadDefaultAttribute (var Attr: RAttributes);
begin
  Attr.FontFamily    := '';
  Attr.FontSize      := 0;
  Attr.FontBold      := False;
  Attr.FontItalic    := False;
  Attr.FontUnderline := False;
  Attr.FontStrike    := False;
  Attr.FontSup       := False;
  Attr.FontSub       := False;
  Attr.Color         := $FF000000;
  Attr.BackColor     := $00000000;
  Attr.Opacity       := 1;
  Attr.RotationAngle := 0;
  Attr.Shadow        := False;
  Attr.ShadowOffsetX := 4;
  Attr.ShadowOffsetY := 4;
  Attr.ShadowColor   := TAlphaColors.Null;
  Attr.ShadowOpacity := 0.2;
  Attr.BaseLine      := 0;
  Attr.TextAlign     := TTextAlign.Leading;
  Attr.LeftMargin    := RTMLSettings.Margins.Left;
  Attr.RightMargin   := RTMLSettings.Margins.Right;
  Attr.LineSpacing   := RTMLSettings.LineSpacing;
end;

procedure TRTMLLabel.CopyAttributes (Source: RAttributes; var Target: RAttributes);
begin
  Target.FontFamily    := Source.FontFamily;
  Target.FontSize      := Source.FontSize;
  Target.FontBold      := Source.FontBold;
  Target.FontItalic    := Source.FontItalic;
  Target.FontUnderline := Source.FontUnderline;
  Target.FontStrike    := Source.FontStrike;
  Target.FontSup       := Source.FontSup;
  Target.FontSub       := Source.FontSub;
  Target.Color         := Source.Color;
  Target.BackColor     := Source.BackColor;
  Target.Opacity       := Source.Opacity;
  Target.RotationAngle := Source.RotationAngle;
  Target.Shadow        := Source.Shadow;
  Target.ShadowOffsetX := Source.ShadowOffsetX;
  Target.ShadowOffsetY := Source.ShadowOffsetY;
  Target.ShadowColor   := Source.ShadowColor;
  Target.ShadowOpacity := Source.ShadowOpacity;
  Target.BaseLine      := Source.BaseLine;
  Target.TextAlign     := Source.TextAlign;
  Target.LeftMargin    := Source.LeftMargin;
  Target.RightMargin   := Source.RightMargin;
  Target.LineSpacing   := Source.LineSpacing;
end;

procedure TRTMLLabel.SetFontAttributes (Attrib: RAttributes; Font: TFont);
begin
  if Attrib.FontBold then
    Font.Style := Font.Style + [TFontStyle.fsBold]
  else
    Font.Style := Font.Style - [TFontStyle.fsBold];

  if Attrib.FontItalic then
    Font.Style := Font.Style + [TFontStyle.fsItalic]
  else
    Font.Style := Font.Style - [TFontStyle.fsItalic];

  if Attrib.FontUnderline then
    Font.Style := Font.Style + [TFontStyle.fsUnderline]
  else
    Font.Style := Font.Style - [TFontStyle.fsUnderline];

  if Attrib.FontStrike then
    Font.Style := Font.Style + [TFontStyle.fsStrikeOut]
  else
    Font.Style := Font.Style - [TFontStyle.fsStrikeOut];

  if Attrib.FontSup or Attrib.FontSub then
  begin
    if Attrib.FontSize <> 0 then
      Font.Size := Attrib.FontSize / 2
    else
      Font.Size := FDefaultFontSize / 2
  end
  else if Attrib.FontSize <> 0 then
    Font.Size := Attrib.FontSize
  else
    Font.Size := FDefaultFontSize;

  if not Attrib.FontFamily.IsEmpty then
    Font.Family := Attrib.FontFamily
  else
    Font.Family := FDefaultFontName;
end;

function TRTMLLabel.RemoveQuotes (s: string): string;
begin
  result := s;

  if (Length (result) >= 2) and (result [1] = '"') and (result [Length (result)] = '"') then
  begin
    Delete (result, 1, 1);
    Delete (result, Length (result), 1);
  end;
end;

function TRTMLLabel.StringToColor (s: string): TAlphaColor;
begin
  result := 0;


  if (Length (s) > 1) and (S [1] = '#') then
  begin
    Delete (s, 1, 1);
    try
      result := StrToInt ('$FF' + s);
    except

    end;
  end;
 end;

procedure TRTMLLabel.GenerateCtrlAttrib;
var
  Node:   PTreeNode;
  Attrib: RAttributes;

  procedure ReadNodes (Node: PTreeNode; Attrib: RAttributes);
  var
    Child:    PTreeNode;
    NodeAttr: PAttribute;
    Ctrl:     PCtrlAttributes;
    i:        integer;
    s:        string;
  begin
    if not Assigned (Node) then exit;

    if Node^.NodeType = ntTag then
    begin
      if (Node^.Token^.UpperToken = 'B') or
         (Node^.Token^.UpperToken = 'STRONG')           then
        Attrib.FontBold := True
      else if Node^.Token^.UpperToken = 'I'             then
        Attrib.FontItalic := True
      else if Node^.Token^.UpperToken = 'U'             then
        Attrib.FontUnderline := True
      else if Node^.Token^.UpperToken = 'STRIKE'        then
        Attrib.FontStrike := True
      else if (Node^.Token^.UpperToken = 'SUPERSCRIPT') or
              (Node^.Token^.UpperToken = 'SUP')         then
      begin
        Attrib.FontSup := True;
        Attrib.FontSub := False;
      end
      else if (Node^.Token^.UpperToken = 'SUBSCRIPT')   or
              (Node^.Token^.UpperToken = 'SUB')         then
      begin
        Attrib.FontSup := False;
        Attrib.FontSub := True;
      end
      else if Node^.Token^.UpperToken = 'FONT'          then
      begin
        for i := 0 to Node^.Attributes.Count - 1 do
        begin
          NodeAttr := PAttribute (Node^.Attributes [i]);
          s        := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
          case i of
            0: Attrib.FontFamily := s;
            1: TryStrToInt(s, Attrib.FontSize);
          end;
        end;
      end
      else if Node^.Token^.UpperToken = 'SHADOW'        then
      begin
        Attrib.Shadow := True;
        for i := 0 to Node^.Attributes.Count - 1 do
        begin
          NodeAttr := PAttribute (Node^.Attributes [i]);
          s        := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
          case i of
            0: Attrib.ShadowColor := StringToColor(s);
            1: TryStrToFloat(s, Attrib.ShadowOpacity);
          end;
        end;
      end
      else if Node^.Token^.UpperToken = 'SHADOWOFFSET'  then
      begin
        for i := 0 to Node^.Attributes.Count - 1 do
        begin
          NodeAttr := PAttribute (Node^.Attributes [i]);
          s        := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
          case i of
            0: TryStrToFloat(s, Attrib.ShadowOffsetX);
            1: TryStrToFloat(s, Attrib.ShadowOffsetY);
          end;
        end;
      end
      else if (Node^.Token^.UpperToken = 'ALIGN') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON)).ToUpper;

        if      s = 'LEFT' then
          Attrib.TextAlign := TTextAlign.Leading
        else if s = 'CENTER' then
          Attrib.TextAlign := TTextAlign.Center
        else if s = 'RIGHT'  then
          Attrib.TextAlign := TTextAlign.Trailing;
      end
      else if (Node^.Token^.UpperToken = 'COLOR') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        Attrib.Color := StringToColor(s);
      end
      else if (Node^.Token^.UpperToken = 'BGCOLOR') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr         := PAttribute (Node^.Attributes [0]);
        s                := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        Attrib.BackColor := StringToColor(s);
      end
      else if (Node^.Token^.UpperToken = 'SIZE') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        TryStrToInt(s, Attrib.FontSize);
      end
      else if (Node^.Token^.UpperToken = 'BASELINE') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        TryStrToFloat(s, Attrib.BaseLine);
      end
      else if (Node^.Token^.UpperToken = 'LEFTMARGIN') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        TryStrToFloat(s, Attrib.LeftMargin);
      end
      else if (Node^.Token^.UpperToken = 'RIGHTMARGIN') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        TryStrToFloat(s, Attrib.RightMargin);
      end
      else if (Node^.Token^.UpperToken = 'LINESPACING') and (Node^.Attributes.Count > 0) then
      begin
        NodeAttr     := PAttribute (Node^.Attributes [0]);
        s            := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
        TryStrToFloat(s, Attrib.LineSpacing);
      end
    end;

    //Read general attributes
(*    if (Node^.NodeType = ntTag) then
    begin
      for i := 0 to Node^.Attributes.Count - 1 do
      begin
        NodeAttr := PAttribute (Node^.Attributes [i]);
        s        := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
{        if NodeAttr^.TokenAttr^.UpperToken = 'VALIGN' then
        begin
          if UpperCase (s) = 'TOP' then
            Attrib.VAlign := vaTop
          else if UpperCase (s) = 'MIDDLE' then
            Attrib.VAlign := vaMiddle
          else if UpperCase (s) = 'BOTTOM' then
            Attrib.VAlign := vaBottom;
        end
        else if NodeAttr^.TokenAttr^.UpperToken = 'COLOR'   then
          Attrib.Color := StringToColor(s)
        else if NodeAttr^.TokenAttr^.UpperToken = 'OPACITY' then
          TryStrToFloat(s, Attrib.Opacity)}
      end;
    end;*)

    Ctrl := nil;
    case Node^.NodeType of
      ntNewLine: begin
        Ctrl           := NewPCtrlAttributes;
        Ctrl^.CtrlType := ctNewLine;
      end;
      ntImage: begin
        Ctrl           := NewPCtrlAttributes;
        Ctrl^.CtrlType := ctImage;

        for i := 0 to Node^.Attributes.Count - 1 do
        begin
          NodeAttr := PAttribute (Node^.Attributes [i]);
          s        := RemoveQuotes(FParser.ReplaceJSONVars(NodeAttr^.Value, JSON));
          case i of
            0: begin
              Ctrl^.Text := s;
              if not TFile.Exists (Ctrl^.Text) then
              begin
                s := TPath.Combine(TPath.GetHomePath, Ctrl^.Text);
                if TFile.Exists (s) then
                  Ctrl^.Text := s
                else
                begin
                  s := TPath.Combine(ExtractFilePath (ParamStr (0)), Ctrl^.Text);
                  if TFile.Exists (s) then
                    Ctrl^.Text := s;
                end;
              end;

              if TFile.Exists (Ctrl^.Text) then
              try
                Ctrl^.Image := TBitmap.CreateFromFile(Ctrl^.Text);
              except
                if Assigned (Ctrl^.Image) then
                  FreeAndNil (Ctrl^.Image);
              end;
            end;
          end;
{         if NodeAttr^.TokenAttr^.UpperToken = 'SRC' then
          begin
          end
          else if NodeAttr^.TokenAttr^.UpperToken = 'WIDTH'  then
            TryStrToInt(s, Ctrl^.Width)
          else if NodeAttr^.TokenAttr^.UpperToken = 'HEIGHT' then
            TryStrToInt(s, Ctrl^.Height)}
        end;
      end;
      ntText: begin
        Ctrl           := NewPCtrlAttributes;
        Ctrl^.CtrlType := ctText;
        Ctrl^.Text     := FParser.ReplaceJSONVars(Node^.Token^.Token, JSON);
      end;
    end;

    if Assigned (Ctrl) then
    begin
      Ctrl^.Node := Node;
      CopyAttributes(Attrib, Ctrl^.Attributes);
      CtrlAttrib.Add(Ctrl);
    end;

    Child := Node^.First;
    while Assigned (Child) do
    begin
      ReadNodes (Child, Attrib);

      Child := Child^.Next;
    end;
  end;
begin
  ClearRows;
  ClearCtrlAttrib;
  if not Assigned (FParser.FRoot) then exit;

  Node := FParser.FRoot^.First;
  while Assigned (Node) do
  begin
    ReadDefaultAttribute(Attrib);
    ReadNodes (Node, Attrib);

    Node := Node^.Next;
  end;
end;

procedure TRTMLLabel.GenerateRows(UsedCanvas: TCanvas);
var
  c, r, i:       integer;
  Row:           PRowInfo;
  Item:          PRowItem;
  NewLine:       boolean;
  Ctrl:          PCtrlAttributes;
  StrLst:        ArrString;
  s:             string;
  ForcesNewLine: boolean;

  procedure DeleteFirstPos;
  var
    i: integer;
  begin
    for i := 1 to Length (StrLst) - 1 do
      StrLst [i - 1] := StrLst [i];

    SetLength (StrLst, Length (StrLst) - 1);
  end;

  procedure AddRow;
  begin
    Row                 := NewPRowInfo;
    Row^.MaxWidth       := Width - (Ctrl^.Attributes.LeftMargin + Ctrl^.Attributes.RightMargin);
    Row^.RemainingWidth := Row^.MaxWidth;
    Row^.Align          := Ctrl^.Attributes.TextAlign;
    Row^.LeftMargin     := Ctrl^.Attributes.LeftMargin;
    Row^.RightMargin    := Ctrl^.Attributes.RightMargin;
    Row^.LineSpacing    := Ctrl^.Attributes.LineSpacing;
    Rows.Add(Row);
  end;

begin
  ClearRows;
  Row     := nil;
  NewLine := False;
  SetLength (StrLst, 0);
  try
    for c := 0 to CtrlAttrib.Count - 1 do
    begin
      Ctrl := PCtrlAttributes (CtrlAttrib [c]);
      if not Assigned (Row) or NewLine then
        AddRow;

      NewLine := False;
      case Ctrl^.CtrlType of
        ctNewLine: NewLine := True;
        ctText: begin
          SetFontAttributes(Ctrl^.Attributes, UsedCanvas.Font);
          SplitText(Ctrl^.Text, Row^.MaxWidth, Row^.RemainingWidth, StrLst, UsedCanvas, ForcesNewLine);
          if ForcesNewLine then
          begin
            AddRow;
            SplitText(Ctrl^.Text, Row^.MaxWidth, Row^.RemainingWidth, StrLst, UsedCanvas, ForcesNewLine);
          end;

          while Length (StrLst) > 0 do
          begin
            s := StrLst [0];
            DeleteFirstPos;

            Item                := NewPRowItem;
            Item^.Ctrl          := Ctrl;
            Item^.Width         := UsedCanvas.TextWidth(s);
            Item^.Height        := UsedCanvas.TextHeight(s);
            Item^.Text          := s;
            Item^.TextGroup     := Ctrl^.Node^.TextGroup;
            Row^.UsedWidth      := Row^.UsedWidth + Item^.Width;
            Row^.RemainingWidth := Row^.RemainingWidth - Item^.Width;
            CopyAttributes(Ctrl^.Attributes, Item^.Attributes);

            if Item^.Height > Row^.Height then
              Row^.Height := Item^.Height;

            Row^.Items.Add(Item);

            if Length (StrLst) = 1 then
            begin
              s := StrLst [0];
              DeleteFirstPos;
              AddRow;
              SplitText(s, Row^.MaxWidth, Row^.RemainingWidth, StrLst, UsedCanvas, ForcesNewLine);
            end;
          end;
        end;
        ctImage: begin
          Item          := NewPRowItem;
          Item^.Ctrl    := Ctrl;
          Item^.IsImage := True;

          if Ctrl^.Width <> 0 then
            Item^.Width := Ctrl^.Width
          else if Assigned (Ctrl^.Image) then
            Item^.Width := Ctrl^.Image.Width;

          if Ctrl^.Height <> 0 then
            Item^.Height := Ctrl^.Height
          else if Assigned (Ctrl^.Image) then
            Item^.Height := Ctrl^.Image.Height;

          Item^.TextGroup     := Ctrl^.Node^.TextGroup;
          Row^.UsedWidth      := Row^.UsedWidth + Item^.Width;
          Row^.RemainingWidth := Row^.RemainingWidth - Item^.Width;
          CopyAttributes(Ctrl^.Attributes, Item^.Attributes);

          if Item^.Height > Row^.Height then
            Row^.Height := Item^.Height;

          Row^.Items.Add(Item);
        end;
      end;
    end;

    for r := 0 to Rows.Count - 1 do
    begin

    end;

  finally
    Finalize (StrLst);
  end;
end;

procedure TRTMLLabel.AnalyzeCode;
begin
  FParser.Source := Text;//FMemo.Text;//Text;
  GenerateCtrlAttrib;
  RepaintLabel;
end;

procedure TRTMLLabel.RepaintLabel;
begin
//  if FUpdating > 0 then exit;

  if FParseToRTML then
    RepaintAsRTML
  else
    RepaintAsLabel;
end;

procedure TRTMLLabel.RepaintAsRTML;
var
  Bmp:       TBitmap;
  r, i:      integer;
  Row:       PRowInfo;
  Item:      PRowItem;
  Curr, p2:  TPointF;
  rect,
  rect2:     TRectF;
  TxtHeight: Single;
  RowDeltaX: Single;
begin
  Bmp := TBitmap.Create;
  Bmp.SetSize(Round(Width), Round(Height));
  Bmp.Clear(TAlphaColors.White);
  {Picture.Bitmap}FBMP.SetSize(Round(Width), Round(Height));
  AssignBitmapToPicture(bmp);//Picture.{Bitmap.}Assign(Bmp);
  GenerateRows (Bmp.Canvas);

  try
    Bmp.Canvas.BeginScene;
    try
      Curr := TPointF.Create(RTMLSettings.Margins.Left, RTMLSettings.Margins.Top);

      for r := 0 to Rows.Count - 1 do
      begin
        Row := PRowInfo (Rows [r]);
        case Row^.Align of
          TTextAlign.Leading:  RowDeltaX := 0;
          TTextAlign.Center:   RowDeltaX := Row^.RemainingWidth / 2;
          TTextAlign.Trailing: RowDeltaX := Row^.RemainingWidth;
        end;
        //RowDeltaX := RowDeltaX + Row^.LeftMargin;
        Curr.X := Row^.LeftMargin;

        for i := 0 to Row^.Items.Count - 1 do
        begin
          Item := PRowItem (Row^.Items [i]);
          p2   := TPointF.Create(Curr.X + Item^.Width, Curr.Y + Item^.Height);
          rect.Create(RowDeltaX + Curr.X, Curr.Y - Item^.Attributes.BaseLine,
                      RowDeltaX + p2.X,   p2.Y   - Item^.Attributes.BaseLine);

          if not Item^.IsImage then
          begin
            SetFontAttributes(Item^.Attributes, Bmp.Canvas.Font);
            if Item^.Attributes.FontSub then
            begin
              TxtHeight := Bmp.Canvas.TextHeight(Item^.Text);
              rect.Create(RowDeltaX + Curr.X, Curr.Y + (-Item^.Attributes.BaseLine) + Row^.Height - TxtHeight,
                          RowDeltaX + p2.X,   Curr.Y + (-Item^.Attributes.BaseLine) + Row^.Height + Item^.Attributes.BaseLine);
            end;

            if Item^.Attributes.BackColor <> $00000000 then
            begin
              Bmp.Canvas.Fill.Color   := Item^.Attributes.BackColor;
              Bmp.Canvas.Stroke.Color := Item^.Attributes.BackColor;
              Bmp.Canvas.FillRect(rect, 0, 0, AllCorners, 100);
            end;

            if Item^.Attributes.Shadow then
            begin
              if Item^.Attributes.ShadowColor = TAlphaColors.Null then
                Bmp.Canvas.Fill.Color := Item^.Attributes.Color
              else
                Bmp.Canvas.Fill.Color := Item^.Attributes.ShadowColor;

              rect2.Create(rect.Left  + Item^.Attributes.ShadowOffsetX, rect.Top    + Item^.Attributes.ShadowOffsetY,
                           rect.Right + Item^.Attributes.ShadowOffsetX, rect.Bottom + Item^.Attributes.ShadowOffsetY);
              Bmp.Canvas.FillText(rect2, Item^.Text, False, Item^.Attributes.ShadowOpacity, [], TTextAlign.taLeading, TTextAlign.taCenter);
            end;

            Bmp.Canvas.Fill.Color := Item^.Attributes.Color;
            Bmp.Canvas.FillText(rect, Item^.Text, False, 1, [], TTextAlign.taLeading, TTextAlign.taCenter);
          end
          else
          begin
            if Assigned (Item^.Ctrl^.Image) then
              Bmp.Canvas.DrawBitmap(Item^.Ctrl^.Image, Item^.Ctrl^.Image.BoundsF, rect, 1);
          end;
          Curr.X := Curr.X + Item^.Width;
        end;
        Curr.X := RTMLSettings.Margins.Left + Row^.LeftMargin;
        Curr.Y := Curr.Y + Row^.Height + Row^.LineSpacing;
      end;
    finally
      Bmp.Canvas.EndScene;
      AssignBitmapToPicture(bmp);
    end;
  finally
    AssignBitmapToPicture(bmp);//Picture.{Bitmap.}Assign(Bmp);
    Bmp.Free ;
  end;
end;

procedure TRTMLLabel.DrawRotatedText(Canvas: TCanvas; const P: TPointF; RadAngle: Single;
  const S: String; HTextAlign, VTextAlign: TTextAlign);
var
  W: Single;
  H: Single;
  R: TRectF;
  SaveMatrix: TMatrix;
  Matrix: TMatrix;
begin
  W := Canvas.TextWidth(S);
  H := Canvas.TextHeight(S);
  case HTextAlign of
    TTextAlign.taCenter:   R.Left := -W / 2;
    TTextAlign.taLeading:  R.Left := 0;
    TTextAlign.taTrailing: R.Left := -W;
  end;
  R.Width := W;
  case VTextAlign of
    TTextAlign.taCenter:   R.Top := -H / 2;
    TTextAlign.taLeading:  R.Top := 0;
    TTextAlign.taTrailing: R.Top := -H;
  end;
  R.Height   := H;
  SaveMatrix := Canvas.Matrix;
  Matrix     := TMatrix.CreateRotation(RadAngle);
  Matrix.m31 := P.X;
  Matrix.m32 := P.Y;
  Canvas.MultiplyMatrix(Matrix);
  Canvas.FillText(R, S, False, 1, [], HTextAlign, VTextAlign);
  Canvas.SetMatrix(SaveMatrix);
end;

procedure TRTMLLabel.RepaintAsLabel;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  Bmp.SetSize(Round(Width), Round(Height));
  Bmp.Clear({TAlphaColors.Null}TAlphaColors.White);
  {Picture.Bitmap}FBMP.SetSize(Round(Width), Round(Height));
  AssignBitmapToPicture(bmp);//Picture.{Bitmap.}Assign(Bmp);
  try
    Bmp.Canvas.BeginScene;
    try
      if not Assigned (TextSettings) then exit;

      Bmp.Canvas.Font.Assign(TextSettings.Font);
      Bmp.Canvas.Fill.Color := TextSettings.FontColor;

      //if RotationAngle = 0 then
        Bmp.Canvas.FillText(Bmp.BoundsF, Text{Memo.Text}, TextSettings.WordWrap, 1, [], TextSettings.HorzAlign, TextSettings.VertAlign);
      //else
      //  DrawRotatedText(Bmp.Canvas, TPointF.Create (RotationCenter.X, Height - RotationCenter.Y), -DegToRad (RotationAngle), Text, TextSettings.HorzAlign, TextSettings.VertAlign);
    finally
      Bmp.Canvas.EndScene;
      AssignBitmapToPicture(bmp);
    end;
  finally
    AssignBitmapToPicture(bmp);//Picture.{Bitmap.}Assign(Bmp);
    Bmp.Free ;
  end;
end;

Procedure TRTMLLabel.AssignBitmapToPicture(pBmp : TBitMap);
var
  Strm : TMemoryStream;
  Surface : TBitmapSurface;
begin

  Strm := TMemoryStream.Create;
  try
    Surface := TBitmapSurface.Create;
    try
      Surface.Assign(pBmp);
      TBitmapCodecManager.SaveToStream(Strm, Surface, '.bmp');
    finally
      Surface.Free;
    end;
    Strm.Position := 0;
    {Picture}FBMP.LoadFromStream(Strm);
    //BMP.LoadFromStream(Strm);
  finally
    Strm.Free;
  end;

  //pBmp.SaveToFile('file.bmp');
  //Picture.LoadFromFile('file.bmp');
end;

{$endregion}

end.
