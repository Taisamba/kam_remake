unit KM_Campaigns;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils,
  KM_CommonClasses, KM_ResourceSprites, KM_Points;


type
  TPicID = record
    RX: TRXType;
    ID: Word;
  end;

  TKMCampaign = class
  private
    fBackGroundPic: TPicID;
    fMapCount: Byte;
    fShortTitle: AnsiString;
    fUnlockedMaps: Byte;
    procedure SetUnlockedMaps(Value: Byte);
  public
    Maps: array of record
      MapName: string;
      MissionText: string;
      Node: TKMPoint;
      PrevMap: shortint; //Should be used to draw connecting dots in Campaign screen
      ScriptPath: string;
    end;
    constructor Create(const aShortTitle: AnsiString; aMapCount: byte; aBackRX: TRXType; aBackID:word);

    property BackGroundPic: TPicID read fBackGroundPic;
    property MapCount: byte read fMapCount;
    property ShortTitle: AnsiString read fShortTitle;
    property UnlockedMaps: byte read fUnlockedMaps write SetUnlockedMaps;

    function MissionText(aIndex: byte): string;
    function SubNodesCount(aIndex: byte): byte;
    function SubNodesPos(aMapIndex: byte; aNodeIndex: byte):TKMPoint;
  end;

  TKMCampaignsCollection = class
  private
    fActiveCampaign:TKMCampaign; //Campaign we are playing
    fActiveCampaignMap:byte; //Map of campaign we are playing, could be different than MaxRevealedMap
    fList:TList;
    procedure CreateTSK;
    procedure CreateTPR;
    function GetCampaign(aIndex:byte):TKMCampaign;
    procedure ScanFolder(const aPath:string);
    procedure LoadProgress(const FileName:string);
    procedure SaveProgress(const FileName:string);
  public
    constructor Create;
    destructor Destroy; override;

    property ActiveCampaign:TKMCampaign read fActiveCampaign write fActiveCampaign;
    property ActiveCampaignMap:byte read fActiveCampaignMap write fActiveCampaignMap;

    function Count:integer;
    property Campaigns[aIndex:byte]:TKMCampaign read GetCampaign; default;
    function CampaignByTitle(const aShortTitle: AnsiString):TKMCampaign;
    procedure UnlockNextMap;

    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
  end;


const
  MAX_CMP_MAPS = 32;
  MAX_CMP_SUBNODES = 16;


implementation
uses KM_Defaults, KM_Log, KM_TextLibrary;


const
  CAMP_HEADER = $FEED; //Just some header to separate right progress files from wrong
  TSK_MAPS = 20;
  TPR_MAPS = 14;

  CampTSKPrev:array [0..TSK_MAPS-1] of shortint =
  (-1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);

  CampTSKNodes: array [0..TSK_MAPS-1] of TKMPoint = (
  (X:180; Y:685), (X:170; Y:470), (X:330; Y:610), (X:452; Y:640), (X:405; Y:540),
  (X:360; Y:435), (X:105; Y:360), (X:150; Y:205), (X:560; Y:535), (X:745; Y:525),
  (X:895; Y:565), (X:315; Y:305), (X:390; Y:285), (X:485; Y:305), (X:590; Y:305),
  (X:830; Y:190), (X:710; Y:160), (X:605; Y: 55), (X:730; Y: 95), (X:830; Y: 65));

  CampTPRPrev:array [0..TPR_MAPS-1] of shortint =
  (-1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);

  CampTPRNodes: array [0..TPR_MAPS-1] of TKMPoint = (
  (X:185; Y:540), (X:190; Y:480), (X:120; Y:440), (X:190; Y:435), (X:240; Y:455),
  (X:380; Y:490), (X:140; Y:220), (X:360; Y:200), (X:525; Y:370), (X:600; Y:375),
  (X:675; Y:205), (X:770; Y:300), (X:785; Y:235), (X:740; Y:175));


{ TCampaignCollection }
constructor TKMCampaignsCollection.Create;
begin
  Inherited;
  fList := TList.Create;
  CreateTSK;
  CreateTPR;
  ScanFolder(ExeDir + 'Campaigns\');

  LoadProgress(ExeDir+'Saves\KaM_Remake_Campaigns.ini');
end;


destructor TKMCampaignsCollection.Destroy;
var i:integer;
begin
  CreateDir(ExeDir+'Saves\'); //Makes the folder incase it was deleted
  SaveProgress(ExeDir+'Saves\KaM_Remake_Campaigns.ini');
  fLog.AppendLog('Campaign.ini saved');

  //Free list objects
  for i:=0 to Count-1 do
    Self[i].Free;

  fList.Free;
  inherited;
end;


procedure TKMCampaignsCollection.CreateTPR;
var i:integer; C:TKMCampaign;
begin
  C := TKMCampaign.Create('TPR', TPR_MAPS, rxGuiMain, 20);

  for i := 0 to C.MapCount - 1 do
  begin
    C.Maps[i].MapName := 'TPR mission ' + IntToStr(i + 1);
    C.Maps[i].MissionText := '';
    C.Maps[i].Node := CampTPRNodes[i];
    C.Maps[i].PrevMap := CampTPRPrev[i];
    C.Maps[i].ScriptPath := ExeDir+'data\mission\dmission'+inttostr(i+1)+'.dat'
  end;

  fList.Add(C);
end;


procedure TKMCampaignsCollection.CreateTSK;
var i:integer; C:TKMCampaign;
begin
  C := TKMCampaign.Create('TSK', TSK_MAPS, rxGuiMainH, 12); //Use the map from the TSK rx, as it is 1024x768 (TPR only has 800x600)

  for i := 0 to C.MapCount - 1 do
  begin
    C.Maps[i].MapName := 'TSK mission ' + IntToStr(i + 1);
    C.Maps[i].MissionText := '';
    C.Maps[i].Node := CampTSKNodes[i];
    C.Maps[i].PrevMap := CampTSKPrev[i];
    C.Maps[i].ScriptPath := ExeDir+'data\mission\mission'+inttostr(i+1)+'.dat';
  end;

  fList.Add(C);
end;


//Scan custom campaigns folders
procedure TKMCampaignsCollection.ScanFolder(const aPath:string);
begin

end;


function TKMCampaignsCollection.GetCampaign(aIndex: byte): TKMCampaign;
begin
  Result := TKMCampaign(fList[aIndex]);
end;


//Read progress from file trying to find matching campaigns
procedure TKMCampaignsCollection.LoadProgress(const FileName: string);
var
  M: TKMemoryStream;
  C: TKMCampaign;
  I, CampCount: Integer;
  CampName: string;
  Unlocked: Byte;
begin
  if not FileExists(FileName) then Exit;

  M := TKMemoryStream.Create;
  try
    M.LoadFromFile(FileName);

    M.Read(I); //Check for wrong file format
    if I <> CAMP_HEADER then Exit; //All campaigns will be kept in initial state

    M.Read(CampCount);
    for I := 0 to CampCount - 1 do
    begin
      M.Read(CampName);
      M.Read(Unlocked);
      C := CampaignByTitle(AnsiString(CampName));
      if C <> nil then
        C.UnlockedMaps := Unlocked;
    end;
  finally
    M.Free;
  end;
end;


procedure TKMCampaignsCollection.SaveProgress(const FileName: string);
var
  M: TKMemoryStream;
  I: word;
begin
  M := TKMemoryStream.Create;
  try
    M.Write(Integer(CAMP_HEADER)); //Identify our format
    M.Write(Count);
    for I := 0 to Count - 1 do
    begin
      M.Write(Campaigns[I].ShortTitle);
      M.Write(Campaigns[I].UnlockedMaps);
    end;

    M.SaveToFile(FileName);
  finally
    M.Free;
  end;
end;


function TKMCampaignsCollection.Count:integer;
begin
  Result := fList.Count;
end;


function TKMCampaignsCollection.CampaignByTitle(const aShortTitle: AnsiString): TKMCampaign;
var i:integer;
begin
  Result := nil;
  for i:=0 to Count-1 do
    if SameText(Campaigns[i].ShortTitle, aShortTitle) then
      Result := Campaigns[i];
end;


procedure TKMCampaignsCollection.UnlockNextMap;
begin
  if ActiveCampaign <> nil then
    ActiveCampaign.UnlockedMaps := ActiveCampaignMap + 1 + 1;
end;


procedure TKMCampaignsCollection.Load(LoadStream: TKMemoryStream);
var s: string;
begin
  LoadStream.ReadAssert('CampaignInfo');
  LoadStream.Read(s);
  fActiveCampaign := CampaignByTitle(s);
  LoadStream.Read(fActiveCampaignMap);
  //If loaded savegame references to missing campaign it will be treated as single-map (fActiveCampaign = nil)
end;


procedure TKMCampaignsCollection.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write('CampaignInfo');
  if fActiveCampaign <> nil then
    SaveStream.Write(fActiveCampaign.ShortTitle)
  else
    SaveStream.Write('');
  SaveStream.Write(fActiveCampaignMap);
end;


{ TKMCampaign }
constructor TKMCampaign.Create(const aShortTitle: AnsiString; aMapCount:byte; aBackRX: TRXType; aBackID:word);
begin
  Inherited Create;
  fShortTitle := aShortTitle;
  fMapCount := aMapCount;
  fBackGroundPic.RX := aBackRX;
  fBackGroundPic.ID := aBackID;
  SetLength(Maps, fMapCount);
  fUnlockedMaps := 1; //1st map should be always unlocked to allow to start campaign
end;


//Mission texts of original campaigns are available in all languages,
//custom campaigns are unlikely to have more texts in more than 1-2 languages
function TKMCampaign.MissionText(aIndex: byte): string;
begin
  if fShortTitle = 'TPR' then
    Result := fTextLibrary.GetSetupString(siCampTPRTexts + aIndex)
  else
  if fShortTitle = 'TSK' then
    Result := fTextLibrary.GetSetupString(siCampTSKTexts + aIndex)
  else
    Result := Maps[aIndex].MissionText;
end;


{When player completes one map we allow to reveal the next one, note that
player may be replaying previous maps, in that case his progress remains the same}
procedure TKMCampaign.SetUnlockedMaps(Value: byte);
begin
  fUnlockedMaps := EnsureRange(Value, fUnlockedMaps, fMapCount - 1);
end;


function TKMCampaign.SubNodesCount(aIndex: byte): byte;
const STEP = 24; //Step each 24px
var Dist: Single;
begin
  if not InRange(Maps[aIndex].PrevMap, 0, fMapCount - 1) then
  begin
    Result := 0;
    Exit;
  end;

  Dist := GetLength(Maps[aIndex].Node, Maps[Maps[aIndex].PrevMap].Node);
  Result := Round(Max((Dist - STEP * 2) / STEP, 0));
end;


function TKMCampaign.SubNodesPos(aMapIndex: byte; aNodeIndex: byte): TKMPoint;
begin
  if (SubNodesCount(aMapIndex) > 0) and (aNodeIndex < SubNodesCount(aMapIndex)) then
  begin
    Result.X := Mix(Maps[aMapIndex].Node.X, Maps[Maps[aMapIndex].PrevMap].Node.X, aNodeIndex/SubNodesCount(aMapIndex));
    Result.Y := Mix(Maps[aMapIndex].Node.Y, Maps[Maps[aMapIndex].PrevMap].Node.Y, aNodeIndex/SubNodesCount(aMapIndex));
  end else begin
    Result.X := 0;
    Result.Y := 0;
  end;
end;


end.
