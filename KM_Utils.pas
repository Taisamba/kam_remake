unit KM_Utils;
{$I KaM_Remake.inc}
interface
uses KromUtils, SysUtils, KM_CommonTypes, KM_Defaults, Math;

  function KMPoint(X, Y: word): TKMPoint; overload;
  function KMPoint(P: TKMPointDir): TKMPoint; overload;
  function KMPointF(X, Y: single): TKMPointF; overload;
  function KMPointF(P: TKMPoint):  TKMPointF; overload;
  function KMPointDir(X, Y, Dir: word): TKMPointDir; overload;
  function KMPointDir(P:TKMPoint; Dir: word): TKMPointDir; overload;
  function KMPointX1(P:TKMPoint): TKMPoint;
  function KMPointX1Y1(X, Y: word): TKMPoint; overload;
  function KMPointX1Y1(P:TKMPoint): TKMPoint; overload;
  function KMPointY1(P:TKMPoint): TKMPoint; overload;
  function KMPointY1(P:TKMPointF): TKMPoint; overload;

  function KMPointRound(P:TKMPointf): TKMPoint;
  function KMSamePoint(P1,P2:TKMPoint): boolean;
  function KMSamePointF(P1,P2:TKMPointF): boolean; overload;
  function KMSamePointF(P1,P2:TKMPointF; Epsilon:single): boolean; overload;
  function KMSamePointDir(P1,P2:TKMPointDir): boolean;

  function KMGetDirection(X,Y: integer): TKMDirection; overload;
  function KMGetDirection(FromPos,ToPos: TKMPoint):TKMDirection; overload;
  function GetDirModifier(Dir1,Dir2:TKMDirection): byte;
  function KMGetCursorDirection(X,Y: integer): TKMDirection;
  function KMGetVertexDir(X,Y: integer):TKMDirection;
  function KMGetVertexTile(P:TKMPoint; Dir: TKMDirection):TKMPoint;
  function KMGetCoord(aPos:TKMPointDir):TKMPointDir;
  function KMGetPointInDir(aPoint:TKMPoint; aDir: TKMDirection): TKMPoint;
  function KMLoopDirection(aDir: byte): TKMDirection;
  function KMGetDiagVertex(P1,P2:TKMPoint): TKMPoint;
  function KMStepIsDiag(P1,P2:TKMPoint):boolean;

  function GetLength(A,B:TKMPoint): single; overload;
  function GetLength(A,B:TKMPointF): single; overload;
  function KMLength(A,B:TKMPoint): single;

  function Mix(A,B:TKMPointF; MixValue:single):TKMPointF; overload;

  procedure KMSwapPoints(var A,B:TKMPoint);

  function GetPositionInGroup(OriginX, OriginY:integer; aDir:TKMDirection; PlaceX,PlaceY:integer):TKMPoint;
  function GetPositionInGroup2(OriginX, OriginY:integer; aDir:TKMDirection; aI, aUnitPerRow:integer; MapX,MapY:integer):TKMPoint;

  function KMRemakeMapPath(aMapName, aExtension:string):string;

  function MapSizeToString(X,Y:integer):string;

  function TypeToString(t:THouseType):string; overload;
  function TypeToString(t:TResourceType):string; overload;
  function TypeToString(t:TUnitType):string; overload;
  function TypeToString(t:TKMPoint):string; overload;
  function TypeToString(t:TKMDirection):string; overload;

implementation
uses KM_LoadLib;


function KMPoint(X, Y: word): TKMPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function KMPointF(P:TKMPoint): TKMPointF;
begin
  Result.X := P.X;
  Result.Y := P.Y;
end;

function KMPoint(P: TKMPointDir): TKMPoint;
begin
  Result := P.Loc;
end;

function KMPointF(X, Y: single): TKMPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;

function KMPointDir(X, Y, Dir: word): TKMPointDir;
begin
  Result.Loc := KMPoint(X,Y);
  Result.Dir := Dir;
end;

function KMPointDir(P:TKMPoint; Dir: word): TKMPointDir;
begin
  Result.Loc := P;
  Result.Dir := Dir;
end;

function KMPointX1Y1(X, Y: word): TKMPoint;
begin
  Result.X := X+1;
  Result.Y := Y+1;
end;

function KMPointX1Y1(P:TKMPoint): TKMPoint;
begin
  Result.X := P.X+1;
  Result.Y := P.Y+1;
end;

function KMPointX1(P:TKMPoint): TKMPoint;
begin
  Result.X := P.X+1;
  Result.Y := P.Y;
end;

function KMPointY1(P:TKMPoint): TKMPoint; overload;
begin
  Result.X := P.X;
  Result.Y := P.Y+1;
end;


function KMPointY1(P:TKMPointF): TKMPoint; overload;
begin
  Result.X := round(P.X);
  Result.Y := round(P.Y)+1;
end;


function KMPointRound(P:TKMPointF): TKMPoint;
begin
  Assert((P.X >= 0) and (P.Y>=0));

  Result.X := round(P.X);
  Result.Y := round(P.Y);
end;


function KMSamePoint(P1,P2:TKMPoint): boolean;
begin
  Result := ( P1.X = P2.X ) and ( P1.Y = P2.Y );
end;


function KMSamePointF(P1,P2:TKMPointF): boolean;
begin
  Result := ( P1.X = P2.X ) and ( P1.Y = P2.Y );
end;

function KMSamePointF(P1,P2:TKMPointF; Epsilon:single): boolean;
begin
  Result := (abs(P1.X - P2.X) < Epsilon) and (abs(P1.Y - P2.Y) < Epsilon);
end;


function KMSamePointDir(P1,P2:TKMPointDir): boolean;
begin
  Result := ( P1.Loc.X = P2.Loc.X ) and ( P1.Loc.Y = P2.Loc.Y ) and ( P1.Dir = P2.Dir );
end;


function KMGetDirection(X,Y: integer): TKMDirection;
const DirectionsBitfield:array[-1..1,-1..1]of TKMDirection =
        ((dir_SE,dir_E,dir_NE),(dir_S,dir_NA,dir_N),(dir_SW,dir_W,dir_NW));
begin
  Result := DirectionsBitfield[sign(X), sign(Y)]; //-1,0,1
end;


function KMGetDirection(FromPos,ToPos: TKMPoint): TKMDirection;
const DirectionsBitfield:array[-1..1,-1..1]of TKMDirection =
        ((dir_NW,dir_W,dir_SW),(dir_N,dir_NA,dir_S),(dir_NE,dir_E,dir_SE));
begin
  Result := DirectionsBitfield[sign(ToPos.X - FromPos.X), sign(ToPos.Y - FromPos.Y)]; //-1,0,1
end;


function GetDirModifier(Dir1,Dir2:TKMDirection): byte;
begin
  Result := abs(byte(Dir1)-byte(KMLoopDirection(byte(Dir2)+4)))+1;
  if Result > 5 then
    Result := 10 - Result; //Inverse it, as the range must always be 1..5
end;


function KMGetCursorDirection(X,Y: integer): TKMDirection;
begin
  Result := dir_NA;
  if KromUtils.GetLength(X,Y) <= DirCursorNARadius then exit; //Use default value dir_NA for the middle

  if abs(X) > abs(Y) then
    if X > 0 then Result := dir_W
             else Result := dir_E;
  if abs(Y) > abs(X) then
    if Y > 0 then Result := dir_N
             else Result := dir_S;
  //Only way to select diagonals is by having X=Y (i.e. the corners), that natural way works best
  if X = Y then
    if X > 0 then Result := dir_NW
             else Result := dir_SE;
  if X = -Y then
    if X > 0 then Result := dir_SW
             else Result := dir_NE;
end;


function KMGetVertexDir(X,Y: integer):TKMDirection;
const DirectionsBitfield:array[-1..0,-1..0]of TKMDirection =
        ((dir_SE,dir_NE),(dir_SW,dir_NW));
begin
  Result := DirectionsBitfield[X,Y];
end;


function KMGetVertexTile(P:TKMPoint; Dir: TKMDirection):TKMPoint;
const 
  XBitField: array[TKMDirection] of smallint = (0,0,1,0,1,0,0,0,0);
  YBitField: array[TKMDirection] of smallint = (0,0,0,0,1,0,1,0,0);
begin
  Result := KMPoint(P.X+XBitField[Dir], P.Y+YBitField[Dir]);
end;


function KMGetCoord(aPos:TKMPointDir):TKMPointDir;
const XYBitfield: array [0..8]of array [1..2]of shortint =
        ((0,0),(0,-1),(1,-1),(1,0),(1,1),(0,1),(-1,1),(-1,0),(-1,-1)); //N/A, N, NE, E, SE, S, SW, W, NW
begin
  Result.Dir := aPos.Dir;
  Result.Loc.X := aPos.Loc.X + XYBitfield[shortint(aPos.Dir+1),1]; //+1 to dir because it is 0..7 not 0..8 like TKMDirection is
  Result.Loc.Y := aPos.Loc.Y + XYBitfield[shortint(aPos.Dir+1),2];
end;


function KMGetPointInDir(aPoint:TKMPoint; aDir: TKMDirection): TKMPoint;
const
  XBitField: array[TKMDirection] of smallint = (0, 0, 1,1,1,0,-1,-1,-1);
  YBitField: array[TKMDirection] of smallint = (0,-1,-1,0,1,1, 1, 0,-1);
begin
  Result := KMPoint(aPoint.X+XBitField[aDir],aPoint.Y+YBitField[aDir]);
end;


function KMLoopDirection(aDir: byte): TKMDirection; //Used after added or subtracting from direction so it is still 1..8
begin
  Result := TKMDirection(((aDir+7) mod 8)+1);
end;


function KMGetDiagVertex(P1,P2:TKMPoint): TKMPoint;
begin
  //Returns the position of the vertex inbetween the two diagonal points (points must be diagonal)
  Result.X := max(P1.X,P2.X);
  Result.Y := max(P1.Y,P2.Y);
end;


function KMStepIsDiag(P1,P2:TKMPoint):boolean;
begin
  Result := ((sign(P2.X-P1.X) <> 0) and
             (sign(P2.Y-P1.Y) <> 0));
end;


function GetLength(A,B:TKMPoint): single; overload;
begin
  Result := sqrt(sqr(A.x-B.x) + sqr(A.y-B.y));
end;


function GetLength(A,B:TKMPointF): single; overload;
begin
  Result := sqrt(sqr(A.x-B.x) + sqr(A.y-B.y));
end;


//Length as straight and diagonal
function KMLength(A,B:TKMPoint): single;
begin
if abs(A.X-B.X) > abs(A.Y-B.Y) then
  Result := abs(A.X-B.X) + abs(A.Y-B.Y)*0.41
else
  Result := abs(A.Y-B.Y) + abs(A.X-B.X)*0.41
end;


function Mix(A,B:TKMPointF; MixValue:single):TKMPointF;
begin
  Result.X := A.X*MixValue + B.X*(1-MixValue);
  Result.Y := A.Y*MixValue + B.Y*(1-MixValue);
end;


procedure KMSwapPoints(var A,B:TKMPoint);
var w:word;
begin
  w:=A.X; A.X:=B.X; B.X:=w;
  w:=A.Y; A.Y:=B.Y; B.Y:=w;
end;


{Returns point where unit should be placed regarding direction & offset from Commanders position}
function GetPositionInGroup(OriginX, OriginY:integer; aDir:TKMDirection; PlaceX,PlaceY:integer):TKMPoint;
const DirAngle:array[TKMDirection]of word =   (0,    0,    45,   90,   135,  180,   225,  270,   315);
const DirRatio:array[TKMDirection]of single = (0,    1,  1.41,    1,  1.41,    1,  1.41,    1,  1.41);
begin
  //If it is < 1 (off map) then set it to 0 (invalid) and GetClosestTile will correct it when walk action is created.
  //GetClosestTile needs to know if the position is not the actual position in the formation
  Result.X := max(OriginX + round( PlaceX*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) - PlaceY*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) ),0);
  Result.Y := max(OriginY + round( PlaceX*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) + PlaceY*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) ),0);
end;


{Returns point where unit should be placed regarding direction & offset from Commanders position}
// 23145     231456
// 6789X     789xxx
function GetPositionInGroup2(OriginX, OriginY:integer; aDir:TKMDirection; aI, aUnitPerRow:integer; MapX,MapY:integer):TKMPoint;
const DirAngle:array[TKMDirection]of word =   (0,    0,    45,   90,   135,  180,   225,  270,   315);
const DirRatio:array[TKMDirection]of single = (0,    1,  1.41,    1,  1.41,    1,  1.41,    1,  1.41);
var PlaceX, PlaceY, ResultX, ResultY:integer;
begin
  Assert(aUnitPerRow>0);
  if aI=1 then begin
    PlaceX := 0;
    PlaceY := 0;
  end else begin
    if aI <= aUnitPerRow div 2 + 1 then
      dec(aI);
    PlaceX := (aI-1) mod aUnitPerRow - aUnitPerRow div 2;
    PlaceY := (aI-1) div aUnitPerRow;
  end;

  ResultX := OriginX + round( PlaceX*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) - PlaceY*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) );
  ResultY := OriginY + round( PlaceX*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) + PlaceY*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) );

  //Fit to bounds
  //If it is off map then GetClosestTile will correct it when walk action is created.
  //GetClosestTile needs to know if the position is not the actual position in the formation
  Result.X := EnsureRange(ResultX, 0, MapX);
  Result.Y := EnsureRange(ResultY, 0, MapY);
end;


function KMRemakeMapPath(aMapName, aExtension:string):string;
begin
  Result := ExeDir+'Maps\'+aMapName+'\'+aMapName;
  if aExtension<>'' then
    Result := Result+'.'+aExtension;
end;


function MapSizeToString(X,Y:integer):string;
begin
  case X*Y of
            1.. 48* 48: Result := 'XS';
     48* 48+1.. 72* 72: Result := 'S';
     72* 72+1..112*112: Result := 'M';
    112*112+1..176*176: Result := 'L';
    176*176+1..256*256: Result := 'XL';
    256*256+1..320*320: Result := 'XXL';
    else                Result := '???';
  end;
end;


{TypeToString routines}
function TypeToString(t:TUnitType):string;
var s:string;
begin
  case byte(t) of
    1..30: s := fTextLibrary.GetTextString(siUnitNames+byte(t));
    31:    s := 'Wolf';
    32:    s := 'Fish';
    33:    s := 'Watersnake';
    34:    s := 'Seastar';
    35:    s := 'Crab';
    36:    s := 'Waterflower';
    37:    s := 'Waterleaf';
    38:    s := 'Duck';
    else   s := 'N/A';
  end;
  Result := s;
end;


function TypeToString(t:THouseType):string;
var s:string;
begin
if byte(t) in [1..HOUSE_COUNT] then
  s:=fTextLibrary.GetTextString(siHouseNames+byte(t))
else
  s:='N/A';
Result:=s;
end;


function TypeToString(t:TResourceType):string;
var s:string;
begin
if byte(t) in [1..28] then
  s:=fTextLibrary.GetTextString(siResourceNames+byte(t))
else
  s:='N/A';
Result:=s;
end;


function TypeToString(t:TKMPoint):string;
begin
  Result:='('+inttostr(t.x)+';'+inttostr(t.y)+')';
end;


function TypeToString(t:TKMDirection):string;
begin
  Result:=TKMDirectionS[byte(t)];
end;

end.
