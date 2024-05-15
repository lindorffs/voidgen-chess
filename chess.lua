
local Chess = {}

local XFEN = require('xfen')
local LSerpent = require('modules/serpent/serpent')
local LLog = require('modules/log/log')

--[[
  trace
  debug
  info
  warn
  error
  fatal
--]]

function Chess.SetLogLevel(ALevel)
  LLog.outfile = 'chess.log'
  LLog.level = ALevel
end

local LSquareName = {
  {'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8'},
  {'b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8'},
  {'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8'},
  {'d1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8'},
  {'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'},
  {'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8'},
  {'g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'g8'},
  {'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8'}
}

function Chess.InRange(ANumber, ALow, AHigh)
  return (ANumber >= ALow) and (ANumber <= AHigh)
end

function Chess.IsBetween(ANumber, ALow, AHigh)
  return (ANumber > ALow) and (ANumber < AHigh) or (ANumber > AHigh) and (ANumber < ALow)
end

function Chess.StrToSquare(AStr)
  return
    string.byte(AStr, 1) - string.byte('a') + 1,
    string.byte(AStr, 2) - string.byte('1') + 1
end

function Chess.SquareToStr(AX, AY)
  return LSquareName[AX][AY]
end

function Chess.StrToMove(AStr)
  local LPromotion = (#AStr == 5) and string.sub(AStr, 5, 5) or nil
  return
    string.byte(AStr, 1) - string.byte('a') + 1,
    string.byte(AStr, 2) - string.byte('1') + 1,
    string.byte(AStr, 3) - string.byte('a') + 1,
    string.byte(AStr, 4) - string.byte('1') + 1,
    LPromotion
end

function Chess.StrToMove2(AStr)
  local LPromotion = (#AStr == 5) and string.sub(AStr, 5, 5) or nil
  return {
    x1 = string.byte(AStr, 1) - string.byte('a') + 1,
    y1 = string.byte(AStr, 2) - string.byte('1') + 1,
    x2 = string.byte(AStr, 3) - string.byte('a') + 1,
    y2 = string.byte(AStr, 4) - string.byte('1') + 1,
    pr = LPromotion
  }
end

function Chess.MoveToStr(AX, AY, AX2, AY2, aPromotion)
  local LSquares = LSquareName[AX][AY] .. LSquareName[AX2][AY2]
  if (aPromotion ~= nil) then
    return LSquares .. string.lower(aPromotion)
  else
    return LSquares
  end
end

function Chess.CastlingMove(ACastling, AKey, ATraditionalCastlingFormat)
  if ATraditionalCastlingFormat then
    if AKey == 'K' then return {x1 = 5, y1 = 1, x2 = 7, y2 = 1, pr = nil} end
    if AKey == 'Q' then return {x1 = 5, y1 = 1, x2 = 3, y2 = 1, pr = nil} end
    if AKey == 'k' then return {x1 = 5, y1 = 8, x2 = 7, y2 = 8, pr = nil} end
    if AKey == 'q' then return {x1 = 5, y1 = 8, x2 = 3, y2 = 8, pr = nil} end
  else
    local LRank = ((AKey == 'K') or (AKey == 'Q')) and 1 or 8
    return {x1 = ACastling.X, y1 = LRank, x2 = ACastling[AKey], y2 = LRank, pr = nil}
  end
end

function Chess.BoardToText(ABoard)
  local result = '+    A B C D E F G H    +\n\n'
  for y = 8, 1, -1 do
    result = result .. tostring(y) .. '   '
    for x = 1, 8 do
      result = result .. ' ' .. ((ABoard[x][y] ~= nil) and ABoard[x][y] or '.')
    end
    result = result .. '    ' .. tostring(y) .. '\n'
  end
  result = result .. '\n+    A B C D E F G H    +'
  return result
end

function Chess.MovePiece(ABoard, x1, y1, x2, y2, APromotion)
  if ABoard[x1][y1] == nil then
    return false
  else
    ABoard[x2][y2] = APromotion or ABoard[x1][y1]
    ABoard[x1][y1] = nil
    return true
  end
end

function Chess.MoveKingRook(ABoard, kx1, ky1, kx2, rx1, rx2)
  if (ABoard[kx1][ky1] == nil) or (ABoard[rx1][ky1] == nil) then
    return false
  else
    local LRook = ABoard[rx1][ky1]
    ABoard[rx1][ky1] = nil
    if kx2 ~= kx1 then
      ABoard[kx2][ky1] = ABoard[kx1][ky1]
      ABoard[kx1][ky1] = nil
    end
    ABoard[rx2][ky1] = LRook
    return true
  end
end

function Chess.OtherColor(AColor)
  return (AColor == 'w') and 'b' or 'w'
end

local LWhitePieces = { P = true, N = true, B = true, R = true, Q = true, K = true }

function Chess.IsWhitePiece(ABoardValue)
  return (ABoardValue ~= nil) and (LWhitePieces[ABoardValue])
end

local LBlackPieces = { p = true, n = true, b = true, r = true, q = true, k = true }

function Chess.IsBlackPiece(ABoardValue)
  return (ABoardValue ~= nil) and (LBlackPieces[ABoardValue])
end

function Chess.IsColor(ABoardValue, AColor)
  return Chess.IsWhitePiece(ABoardValue) and (AColor == 'w') or Chess.IsBlackPiece(ABoardValue) and (AColor == 'b')
end

function Chess.IsSameColor(ABoardValue1, ABoardValue2)
  return Chess.IsWhitePiece(ABoardValue1) and Chess.IsWhitePiece(ABoardValue2) or Chess.IsBlackPiece(ABoardValue1) and Chess.IsBlackPiece(ABoardValue2)
end

function Chess.IsPawn(ABoardValue)
  return (ABoardValue == 'P') or (ABoardValue == 'p')
end

function Chess.IsKnight(ABoardValue)
  return (ABoardValue == 'N') or (ABoardValue == 'n')
end

function Chess.IsBishop(ABoardValue)
  return (ABoardValue == 'B') or (ABoardValue == 'b')
end

function Chess.IsRook(ABoardValue)
  return (ABoardValue == 'R') or (ABoardValue == 'r')
end

function Chess.IsQueen(ABoardValue)
  return (ABoardValue == 'Q') or (ABoardValue == 'q')
end

function Chess.IsKing(ABoardValue)
  return (ABoardValue == 'K') or (ABoardValue == 'k')
end

function Chess.StrToBoard(AFen1)
  local result = {{}, {}, {}, {}, {}, {}, {}, {}}
  local i, x, y = 1, 1, 8
  while i <= #AFen1 do
    local s = string.sub(AFen1, i, i)
    if s == '/' then
      y = y - 1
      x = 1
    elseif string.match(s, '%d') then
      for j = 1, tonumber(s) do
        result[x][y] = nil
        x = x + 1
      end
    else
      result[x][y] = s
      x = x + 1
    end
    i = i + 1
  end
  return result
end

function Chess.EncodePosition(AFen)
  local t = {}
  for s in string.gmatch(AFen or 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', '%S+') do
    t[#t + 1] = s
  end
  assert(#t == 6, AFen)
  local LBoard = Chess.StrToBoard(t[1])
  return {
    piecePlacement = LBoard,
    activeColor = t[2],
    castlingAvailability = XFEN.EncodeCastling(t[3], LBoard),
    enPassantTargetSquare = t[4],
    halfmoveClock = tonumber(t[5]),
    fullmoveNumber = tonumber(t[6])
  }
end

function Chess.BoardToStr(ABoard)
  local result = ''
  for y = 8, 1, -1 do
    local x = 1
    while x <= 8 do
      if ABoard[x][y] ~= nil then
        result = result .. ABoard[x][y]
        x = x + 1
      else
        local n = 0
        while (x <= 8) and (ABoard[x][y] == nil) do
          n, x = n + 1, x + 1
        end
        result = result .. tostring(n)
      end
    end
    if y > 1 then result = result .. '/' end
  end
  return result
end

function Chess.DecodePosition(APos)
  return string.format(
    '%s %s %s %s %d %d',
    Chess.BoardToStr(APos.piecePlacement),
    APos.activeColor,
    XFEN.DecodeCastling(APos.castlingAvailability, APos.piecePlacement, false),
    APos.enPassantTargetSquare,
    APos.halfmoveClock,
    APos.fullmoveNumber
  )
end

local LVectors = {
  {x =-1, y = 1},
  {x = 1, y = 1},
  {x =-1, y =-1},
  {x = 1, y =-1},
  {x =-1, y = 0},
  {x = 1, y = 0},
  {x = 0, y = 1},
  {x = 0, y =-1},
  {x = 1, y = 2},
  {x = 2, y = 1},
  {x = 2, y =-1},
  {x = 1, y =-2},
  {x =-1, y =-2},
  {x =-2, y =-1},
  {x =-2, y = 1},
  {x =-1, y = 2}
}

function Chess.ComputeTargetSquare(AX, AY, AVectorIndex)
  local x2, y2 =
    AX + LVectors[AVectorIndex].x,
    AY + LVectors[AVectorIndex].y
  if Chess.InRange(x2, 1, 8) and Chess.InRange(y2, 1, 8) then
    return true, x2, y2
  else
    return false
  end
end

function Chess.GenMoves(ABoard, AColor, AExtraPawnMoves)
  local j, k
  local result = {}
  for x = 1, 8 do
    for y = 1, 8 do
      if ABoard[x][y] ~= nil then
        if Chess.IsColor(ABoard[x][y], AColor) then
          if Chess.IsPawn(ABoard[x][y]) then
            --~ if Chess.IsWhitePiece(ABoard[x][y]) then
            --~ if ABoard[x][y] == 'P' then
            if AColor == 'w' then
              j, k = 1, 2
            else
              j, k = 3, 4
            end
            for i = j, k do
              local success, x2, y2 = Chess.ComputeTargetSquare(x, y, i)
              if success and (Chess.IsColor(ABoard[x2][y2], Chess.OtherColor(AColor)) or ((ABoard[x2][y2] == nil) and AExtraPawnMoves)) then
                if (AColor == 'w') and (y2 == 8) or (AColor == 'b') and (y2 == 1) then
                  result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'r'}
                  result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'n'}
                  result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'b'}
                  result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'q'}
                else
                  result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = nil}
                end
              end
            end
          elseif Chess.IsKnight(ABoard[x][y]) or Chess.IsKing(ABoard[x][y]) then
            if Chess.IsKnight(ABoard[x][y]) then
              j, k = 9, 16
            elseif Chess.IsKing(ABoard[x][y]) then
              j, k = 1, 8
            end
            for i = j, k do
              local success, x2, y2 = Chess.ComputeTargetSquare(x, y, i)
              if success and not Chess.IsColor(ABoard[x2][y2], AColor) then
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = nil}
              end
            end
          elseif Chess.IsBishop(ABoard[x][y]) or Chess.IsRook(ABoard[x][y]) or Chess.IsQueen(ABoard[x][y]) then
            if Chess.IsBishop(ABoard[x][y]) then
              j, k = 1, 4
            elseif Chess.IsRook(ABoard[x][y]) then
              j, k = 5, 8
            elseif Chess.IsQueen(ABoard[x][y]) then
              j, k = 1, 8
            end
            for i = j, k do
              local success, x2, y2 = Chess.ComputeTargetSquare(x, y, i)
              while success and not Chess.IsColor(ABoard[x2][y2], AColor) do
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = nil}
                if ABoard[x2][y2] ~= nil then
                  break
                end
                success, x2, y2 = Chess.ComputeTargetSquare(x2, y2, i)
              end
            end
          end
        end
      end
    end
  end
  return result
end

function Chess.Think(APos)
  local LMoves = Chess.GenMoves(APos.piecePlacement, Chess.OtherColor(APos.activeColor), true)
  local LCheck = false
  local LCastleCheck = {
    K = false,
    Q = false,
    k = false,
    q = false
  }
  for _, v in ipairs(LMoves) do
    local x2, y2 = v.x2, v.y2
    if Chess.IsKing(APos.piecePlacement[x2][y2]) then
      LCheck = true
    end

    if APos.castlingAvailability.X ~= nil then
      if (APos.activeColor == 'w') and (y2 == 1) then
        if Chess.IsBetween(x2, APos.castlingAvailability.X, 7) then
          LCastleCheck.K = true
        elseif Chess.IsBetween(x2, APos.castlingAvailability.X, 3) then
          LCastleCheck.Q = true
        end
      elseif (APos.activeColor == 'b') and (y2 == 8) then
        if Chess.IsBetween(x2, APos.castlingAvailability.X, 7) then
          LCastleCheck.k = true
        elseif Chess.IsBetween(x2, APos.castlingAvailability.X, 3) then
          LCastleCheck.q = true
        end
      end
    end
  end
  local result = {
    check = LCheck and true or false,
    castlingCheck = LCastleCheck
  }
  return result
end

local function IsPathFree(ABoard, AColor, AKingX, ARookX)
  LLog.trace(string.format('IsPathFree(,%s,%s,%s)', AColor, AKingX, ARookX))
  local result = true
  local y = (AColor == 'w') and 1 or 8
  result = result and (ABoard[AKingX][y] == ((AColor == 'w') and 'K' or 'k'))
  result = result and (ABoard[ARookX][y] == ((AColor == 'w') and 'R' or 'r'))
  if ARookX > AKingX then
    for x = math.min(AKingX, 6), math.max(ARookX, 7), 1 do
      result = result and ((ABoard[x][y] == nil) or (x == AKingX) or (x == ARookX))
    end
  else
    for x = math.max(AKingX, 4), math.min(ARookX, 3), -1 do
      result = result and ((ABoard[x][y] == nil) or (x == AKingX) or (x == ARookX))
    end
  end
  return result
end

function Chess.GenSpecial(APos, AColor)
  local j, k
  local result = {}
  local extraPositionData = Chess.Think(APos)
  local success, x2, y2

  local function GenCastling(ASymbol)
    LLog.trace(string.format('GenCastling(%s)', ASymbol))
    local LColor = ((ASymbol == 'K') or (ASymbol == 'Q')) and 'w' or 'b'
    local condition1 = (APos.castlingAvailability[ASymbol] ~= nil)

    if not condition1 then
      return
    end

    local condition2 = IsPathFree(APos.piecePlacement, LColor, APos.castlingAvailability.X, APos.castlingAvailability[ASymbol])
    local condition3 = not extraPositionData.castlingCheck[ASymbol]

    if condition1
    and condition2
    and condition3 then
      result[#result + 1] = Chess.CastlingMove(APos.castlingAvailability, ASymbol, false)
    end
  end

  for x = 1, 8 do
    for y = 1, 8 do
      if APos.piecePlacement[x][y] ~= nil then
        if Chess.IsColor(APos.piecePlacement[x][y], AColor) then
          if Chess.IsPawn(APos.piecePlacement[x][y]) then
            --~ if Chess.IsWhitePiece(APos.piecePlacement[x][y]) then
            if APos.piecePlacement[x][y] == 'P' then
              j = 7
            else
              j = 8
            end
            success, x2, y2 = Chess.ComputeTargetSquare(x, y, j)
            if success and (APos.piecePlacement[x2][y2] == nil) then
              if (AColor == 'w') and (y2 == 8) or (AColor == 'b') and (y2 == 1) then
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'r'}
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'n'}
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'b'}
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = 'q'}
              else
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = nil}
              end
              if y == ((AColor == 'w') and 2 or 7) then
                success, x2, y2 = Chess.ComputeTargetSquare(x2, y2, j)
                if success and (APos.piecePlacement[x2][y2] == nil) then
                  result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = nil}
                end
              end
            end
            if Chess.IsWhitePiece(APos.piecePlacement[x][y]) then
              j, k = 1, 2
            else
              j, k = 3, 4
            end
            for i = j, k do
              success, x2, y2 = Chess.ComputeTargetSquare(x, y, i)
              if success
              and (APos.piecePlacement[x2][y2] == nil)
              and (LSquareName[x2][y2] == APos.enPassantTargetSquare) then
                result[#result + 1] = {x1 = x, y1 = y, x2 = x2, y2 = y2, pr = nil}
              end
            end
          elseif Chess.IsKing(APos.piecePlacement[x][y]) and not extraPositionData.check then
            if Chess.IsWhitePiece(APos.piecePlacement[x][y]) then
              GenCastling('K')
              GenCastling('Q')
            else
              GenCastling('k')
              GenCastling('q')
            end
          end
        end
      end
    end
  end
  return result
end

function Chess.RemoveCastling(APos, AChar)
  APos.castlingAvailability[AChar] = nil
end

function Chess.DoMove(APos, x1, y1, x2, y2, APromotion)
  --~ LLog.trace(string.format('DoMove(,%d,%d,%d,%d,%s)', x1, y1, x2, y2, tostring(APromotion)))
  assert(APos.piecePlacement[x1][y1] ~= nil, 'Cannot do move ' .. LSquareName[x1][y1] .. LSquareName[x2][y2] .. ': No piece on start square')
  local result = true
  local LCastling = false
  if Chess.IsKing(APos.piecePlacement[x1][y1]) and (x1 == APos.castlingAvailability.X) then
    if (y1 == 1) and (APos.activeColor == 'w') then
      Chess.RemoveCastling(APos, 'K')
      Chess.RemoveCastling(APos, 'Q')
    elseif (y1 == 8)  and (APos.activeColor == 'b') then
      Chess.RemoveCastling(APos, 'k')
      Chess.RemoveCastling(APos, 'q')
    end
  end
  if Chess.IsRook(APos.piecePlacement[x1][y1]) then
    if (y1 == 1) and (APos.activeColor == 'w') then
      if (x1 == APos.castlingAvailability.K) then Chess.RemoveCastling(APos, 'K') end
      if (x1 == APos.castlingAvailability.Q) then Chess.RemoveCastling(APos, 'Q') end
    elseif (y1 == 8) and (APos.activeColor == 'b') then
      if (x1 == APos.castlingAvailability.k) then Chess.RemoveCastling(APos, 'k') end
      if (x1 == APos.castlingAvailability.q) then Chess.RemoveCastling(APos, 'q') end
    end
  end
  if Chess.IsPawn(APos.piecePlacement[x1][y1]) and (math.abs(y2 - y1) == 2) then
    APos.enPassantTargetSquare = LSquareName[x1][(APos.activeColor == 'w') and 3 or 6]
  else
    APos.enPassantTargetSquare = '-'
  end

  if Chess.IsKing(APos.piecePlacement[x1][y1]) and Chess.IsRook(APos.piecePlacement[x2][y2]) and Chess.IsSameColor(APos.piecePlacement[x1][y1], APos.piecePlacement[x2][y2]) then
    if x2 > x1 then
      result = result and Chess.MoveKingRook(APos.piecePlacement, x1, y1, 7, x2, 6)
    else
      result = result and Chess.MoveKingRook(APos.piecePlacement, x1, y1, 3, x2, 4)
    end
    LCastling = true
  end

  if Chess.IsPawn(APos.piecePlacement[x1][y1]) and (math.abs(x2 - x1) == 1) and (APos.piecePlacement[x2][y2] == nil) then
    APos.piecePlacement[x2][y1] = nil
  end
  if Chess.IsPawn(APos.piecePlacement[x1][y1]) or (APos.piecePlacement[x2][y2] ~= nil) then
    APos.halfmoveClock = 0
  else
    APos.halfmoveClock = APos.halfmoveClock + 1
  end

  if APos.activeColor == 'b' then
    APos.fullmoveNumber = APos.fullmoveNumber + 1
  end

  if Chess.IsPawn(APos.piecePlacement[x1][y1]) and ((y2 == 1) or (y2 == 8)) then
    if APromotion == nil then
      APromotion = (APos.activeColor == 'w') and 'Q' or 'q'
    else
      APromotion = (APos.activeColor == 'w') and string.upper(APromotion) or string.lower(APromotion)
    end
  else
    APromotion = nil
  end
  
  -- Update castling rights when a rook is captured
  if Chess.IsRook(APos.piecePlacement[x2][y2]) then
    if (y2 == 1) and (APos.activeColor == 'b') then
      if (x2 == APos.castlingAvailability.K) then Chess.RemoveCastling(APos, 'K') end
      if (x2 == APos.castlingAvailability.Q) then Chess.RemoveCastling(APos, 'Q') end
    elseif (y2 == 8) and (APos.activeColor == 'w') then
      if (x2 == APos.castlingAvailability.k) then Chess.RemoveCastling(APos, 'k') end
      if (x2 == APos.castlingAvailability.q) then Chess.RemoveCastling(APos, 'q') end
    end
  end
  
  if not LCastling then
    result = result and Chess.MovePiece(APos.piecePlacement, x1, y1, x2, y2, APromotion)
  end
  APos.activeColor = Chess.OtherColor(APos.activeColor)
  return result
end

local function CopyTable(orig) -- http://lua-users.org/wiki/CopyTable
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[CopyTable(orig_key)] = CopyTable(orig_value)
    end
    setmetatable(copy, CopyTable(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

function Chess.CopyPosition(APos)
  local result = {}
  result.piecePlacement = {{}, {}, {}, {}, {}, {}, {}, {}}
  for x = 1, 8 do
    for y = 1, 8 do
      result.piecePlacement[x][y] = APos.piecePlacement[x][y]
    end
  end
  result.activeColor = APos.activeColor
  --~ result.castlingAvailability = APos.castlingAvailability
  result.castlingAvailability = CopyTable(APos.castlingAvailability)
  result.enPassantTargetSquare = APos.enPassantTargetSquare
  result.halfmoveClock = APos.halfmoveClock
  result.fullmoveNumber = APos.fullmoveNumber
  return result
end

function Chess.GenLegal(APos)
  local LT1 = Chess.GenMoves(APos.piecePlacement, APos.activeColor)
  local LT2 = Chess.GenSpecial(APos, APos.activeColor)
  local LT3 = {}
  for _, v in ipairs(LT1) do LT3[#LT3 + 1] = v end
  for _, v in ipairs(LT2) do LT3[#LT3 + 1] = v end
  local result = {}
  for _, v in ipairs(LT3) do
    local x1, y1, x2, y2, pr = v.x1, v.y1, v.x2, v.y2, v.pr
    local LPos1 = Chess.CopyPosition(APos)
    if Chess.DoMove(LPos1, x1, y1, x2, y2, v.pr) then
      LPos1.activeColor = Chess.OtherColor(LPos1.activeColor)
      local LThink = Chess.Think(LPos1)
      if LThink.check then
      else
        result[#result + 1] = v
      end
    else
    end
  end
  return result
end

function Chess.IsEnPassant(APos, AMove)
  local x1, y1, x2, y2 = AMove.x1, AMove.y1, AMove.x2, AMove.y2
  if Chess.IsPawn(APos.piecePlacement[x1][y1])
  and (x2 ~= x1)
  and (APos.piecePlacement[x2][y2] == nil) then
    return true, LSquareName[x2][y1]
  else
    return false
  end
end

function Chess.IsPromotion(APos, AMove)
  local x1, y1, x2, y2 = AMove.x1, AMove.y1, AMove.x2, AMove.y2
  return Chess.IsPawn(APos.piecePlacement[x1][y1]) and ((y2 == 1) or (y2 == 8))
end

function Chess.IsCastling(APos, AMove)
  local x1, y1, x2, y2 = AMove.x1, AMove.y1, AMove.x2, AMove.y2
  local result = Chess.IsKing(APos.piecePlacement[x1][y1]) and Chess.IsRook(APos.piecePlacement[x2][y2]) and Chess.IsSameColor(APos.piecePlacement[x1][y1], APos.piecePlacement[x2][y2])
  local x3, x4 = 0, 0
  if result then
    if x2 > x1 then
      x3 = 7
      x4 = 6
    else
      x3 = 3
      x4 = 4
    end
  end
  return result, y1, x1, x2, x3, x4
end

local function Material(APos)
  local result = 0
  for x = 1, 8 do
    for y = 1, 8 do
      local LPiece = APos.piecePlacement[x][y]
      if LPiece ~= nil then
        local d = 0
        if     Chess.IsPawn  (LPiece) then d =  100
        elseif Chess.IsKnight(LPiece) then d =  340
        elseif Chess.IsBishop(LPiece) then d =  350
        elseif Chess.IsRook  (LPiece) then d =  800
        elseif Chess.IsQueen (LPiece) then d = 1500
        elseif Chess.IsKing  (LPiece) then d = 5000
        end
        if Chess.IsBlackPiece(LPiece) then
          d = -1 * d
        end
        result = result + d
      end
    end
  end
  if APos.activeColor == 'b' then
    result = -1 * result
  end
  return result
end

local function GenBest(APos)
--!strict
  --~ local LT1 = Chess.GenMoves(APos.piecePlacement, APos.activeColor)
  --~ local LT2 = Chess.GenSpecial(APos, APos.activeColor)
  --~ local LT3 = {}
  --~ for _, v in ipairs(LT1) do LT3[#LT3 + 1] = v end
  --~ for _, v in ipairs(LT2) do LT3[#LT3 + 1] = v end
  
  LT3 = Chess.GenLegal(APos)
  
  local LPos1, LPos2, LPos3 = {}, {}, {}
  local LCount = 0
  local result = {}
  local LCheckmate = false
  local LThink = nil
  
  for k, v in ipairs(LT3) do
  
    local x1, y1, x2, y2, pr = v.x1, v.y1, v.x2, v.y2, v.pr
    
    LPos1 = Chess.CopyPosition(APos)
    
    if Chess.DoMove(LPos1, x1, y1, x2, y2, pr) then
    
      local LMin2 = 100000
      
      --~ LT1 = Chess.GenMoves(LPos1.piecePlacement, LPos1.activeColor)
      LT1 = Chess.GenLegal(LPos1)
      
      if #LT1 == 0 then
        local LThink = Chess.Think(LPos1)
        LCheckmate = LThink.check
      else
        LCheckmate = false
      end
      
      for kk, vv in ipairs(LT1) do
        
        local xx1, yy1, xx2, yy2, ppr = vv.x1, vv.y1, vv.x2, vv.y2, vv.pr
        
        LPos2 = Chess.CopyPosition(LPos1)
        
        if Chess.IsKing(LPos2.piecePlacement[xx2][yy2]) then
        
          LMin2 = -100000
          break
          
        elseif Chess.DoMove(LPos2, xx1, yy1, xx2, yy2, ppr) then
        
          local LMax3 = -100000
          
          LT2 = Chess.GenMoves(LPos2.piecePlacement, LPos2.activeColor)
          
          for kkk, vvv in ipairs(LT2) do
            
            local xxx1, yyy1, xxx2, yyy2, pppr = vvv.x1, vvv.y1, vvv.x2, vvv.y2, vvv.pr

            LPos3 = Chess.CopyPosition(LPos2)
            
            if Chess.DoMove(LPos3, xxx1, yyy1, xxx2, yyy2, pppr) then
            
              LPos3.activeColor = Chess.OtherColor(LPos3.activeColor)
              
              local LMaterial3 = Material(LPos3)
              
              if LMaterial3 > LMax3 then
                LMax3 = LMaterial3
              end
              
            end

          end
          
          if LMax3 < LMin2 then
            LMin2 = LMax3
          end
          
        end
      end
      
      table.insert(result, {v, LMin2 + (LCheckmate and 1 or 0)})

    end
  end
  
  table.sort(result, function(a, b) return a[2] > b[2] end)
  
  return result
--!strict
end

function Chess.IsProtectedMove(APos, AX, AY)
  if (AX == 1) or (AX == 8) then
    return false
  end
  if (APos.activeColor == 'w') then
    if AX < 5 then
      return APos.piecePlacement[AX - 1][AY - 1] == 'P'
    else
      return APos.piecePlacement[AX + 1][AY - 1] == 'P'
    end
  else
    if AX < 5 then
      return APos.piecePlacement[AX - 1][AY + 1] == 'p'
    else
      return APos.piecePlacement[AX + 1][AY + 1] == 'p'
    end
  end
end

local function Readable(ATable)
  local result = {}
  for i = 1, #ATable do
    local x1, y1, x2, y2, pr = ATable[i][1].x1, ATable[i][1].y1, ATable[i][1].x2, ATable[i][1].y2, ATable[i][1].pr
    table.insert(result, {Chess.MoveToStr(x1, y1, x2, y2, pr), ATable[i][2]})
  end
  return result
end

local function CountEqualValues(AMoveList)
  local LFirstMoveValue = AMoveList[1][2]
  local result = 1
  while (result < #AMoveList) and (AMoveList[result + 1][2] == LFirstMoveValue) do
    result = result + 1
  end
  return result
end

function Chess.BestMove(APos, AChess960)

  local LBest = GenBest(APos)
  local LReadable = Readable(LBest)
  
  LLog.info(LSerpent.line(LReadable, {comment = false}))

  if (#LBest == 0 or #LBest[1] == 0) then
	return nil
  end

  local LBest2 = {}
  table.insert(LBest2, {LBest[1][1], 0})
  local i = 2
  while (i <= #LBest) and (LBest[i][2] == LBest[i - 1][2]) do
    table.insert(LBest2, {LBest[i][1], 0})
    i = i + 1
  end
  
  i = 1
  
  --~ local r = math.random(1, 6)
  
  while i <= #LBest2 do
  
    local x1, y1, x2, y2, pr = LBest2[i][1].x1, LBest2[i][1].y1, LBest2[i][1].x2, LBest2[i][1].y2, LBest2[i][1].pr
    
    --~ if r < 5 then
      
      --~ if Chess.IsPawn(APos.piecePlacement[x1][y1]) then
        --~ LBest2[i][2] = LBest2[i][2] + 1
        --~ LBest2[i][2] = LBest2[i][2] + (((x1 == 4) or (x1 == 5)) and 1 or 0)
        --~ LBest2[i][2] = LBest2[i][2] + (Chess.IsProtectedMove(APos, x2, y2) and 1 or 0)
        --~ LBest2[i][2] = LBest2[i][2] + (Chess.IsEnPassant(APos, LBest2[i][1]) and 10 or 0)
      --~ end
    
    --~ else
      
      --~ if Chess.IsPawn(APos.piecePlacement[x1][y1]) then
        --~ LBest2[i][2] = LBest2[i][2] - 1
      
      --~ elseif Chess.IsKnight(APos.piecePlacement[x1][y1]) then
        --~ if (x2 ~= 1) and (x2 ~= 8) and ((y2 ~= 1) or (APos.activeColor == 'b')) and ((y2 ~= 8) or (APos.activeColor == 'w')) then
          --~ LBest2[i][2] = LBest2[i][2] + 1
        --~ end
        --~ if (APos.activeColor == 'w') and (x1 == 1)
        --~ or (APos.activeColor == 'b') and (x1 == 8) then
          --~ LBest2[i][2] = LBest2[i][2] + 1
        --~ end
      
      --~ elseif Chess.IsBishop(APos.piecePlacement[x1][y1]) then
        --~ if (r == 6) then
          --~ LBest2[i][2] = LBest2[i][2] + 1
        --~ end
        --~ if ((APos.activeColor == 'w') and ((y2 ~= 3) or (APos.piecePlacement[x2][2] ~= 'P')))
        --~ or ((APos.activeColor == 'b') and ((y2 ~= 6) or (APos.piecePlacement[x2][7] ~= 'p'))) then
          --~ LBest2[i][2] = LBest2[i][2] + 1
        --~ end
        --~ if (APos.activeColor == 'w') and (x1 == 1)
        --~ or (APos.activeColor == 'b') and (x1 == 8) then
          --~ LBest2[i][2] = LBest2[i][2] + 1
        --~ end
      --~ end
    --~ end
    
    if Chess.IsKing(APos.piecePlacement[x1][y1]) then
      LBest2[i][2] = LBest2[i][2] + (Chess.IsCastling(APos, LBest2[i][1]) and 10 or -1)
    end
    
    i = i + 1
  end
  
  table.sort(LBest2, function(a, b) return a[2] > b[2] end)
  
  LReadable = Readable(LBest2)
  LLog.info(LSerpent.line(LReadable, {comment = false}))
  
  local LCount = CountEqualValues(LBest2)
  LLog.debug(string.format('%d moves with same value', LCount))
  
  local LMoveIndex = math.random(1, LCount)
  local LMove = LBest2[LMoveIndex][1]
  local LMoveStr = Chess.MoveToStr(LMove.x1, LMove.y1, LMove.x2, LMove.y2, LMove.pr)
  
  -- Change castling notation if necessary
  if (not AChess960) and Chess.IsCastling(APos, LMove) then
    local LMoveStr1 = LMoveStr
    if LMove.x2 > LMove.x1 then
      LMove.x2 = 7
    else
      LMove.x2 = 3
    end
    LMoveStr = Chess.MoveToStr(LMove.x1, LMove.y1, LMove.x2, LMove.y2, LMove.pr)
    LLog.warn(string.format('%s -> %s', LMoveStr1, LMoveStr))
  end
  
  return LMoveStr
end

function Chess.CountLegalMove(APos, ADepth)
  --~ LLog.debug('APos.castlingAvailability = ', LSerpent.line(APos.castlingAvailability, {comment = false}))
  local LPos = Chess.CopyPosition(APos)
  --~ LLog.debug('LPos.castlingAvailability = ', LSerpent.line(LPos.castlingAvailability, {comment = false}))
  local LLegal = Chess.GenLegal(LPos)
  if ADepth < 2 then
    return #LLegal
  else
    local LTotal = 0
    for _, v in ipairs(LLegal) do
      local x1, y1, x2, y2, pr = v.x1, v.y1, v.x2, v.y2, v.pr
      local LPos2 = Chess.CopyPosition(LPos)
      if Chess.DoMove(LPos2, x1, y1, x2, y2, pr) then
        LTotal = LTotal + Chess.CountLegalMove(LPos2, ADepth - 1)
      end
    end
    return LTotal
  end
end

return Chess
