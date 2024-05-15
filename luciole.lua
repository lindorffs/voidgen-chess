
local Chess = require('chess')

Chess.SetLogLevel('info')

--[[
  trace
  debug
  info
  warn
  error
  fatal
--]]

local LFile = io.open('luciole.log', 'a')

function LogLn(AText)
  LFile:write(AText .. '\n')
  LFile:flush()
end

local LName, LAuthor = 'Luciole 0.0.9.1', 'Roland Chastain'

LogLn(string.format('** %s, %s', LName, _VERSION .. (jit and ' (LuaJIT)' or '')))

LPos = Chess.EncodePosition()
local LChess960 = false
local LMoveHistoryAvailable = false

function OnNewGame()
  LPos = Chess.EncodePosition()
end

function OnStartPos()
  LPos = Chess.EncodePosition()
end

function OnFen(AFen)
  LPos = Chess.EncodePosition(AFen)
end

function OnMove(AMove)
  local x1, y1, x2, y2, pr = Chess.StrToMove(AMove)
  if Chess.IsKing(LPos.piecePlacement[x1][y1]) and (math.abs(x2 - x1) == 2) and ((LPos.piecePlacement[x2][y2]) == nil) then
    if (x2 - x1 == 2) then
      x2 = 8 -- e1g1, e8g8
    else
      x2 = 1 -- e1c1, e8c8
    end
    LogLn(string.format('** %s -> %s', AMove, Chess.MoveToStr(x1, y1, x2, y2, nil)))
  end
  Chess.DoMove(LPos, x1, y1, x2, y2, pr)
end

function OnGo(AWTime, ABTime, AMovesToGo)
  local LTime = os.clock()
  local LMove = Chess.BestMove(LPos, LChess960)
  LTime = os.clock() - LTime
  LogLn(string.format('** Time elapsed: %.2f s', LTime))
  io.write(string.format('bestmove %s\n', LMove))
  io.flush()
  return LMove
end

function OnSetOption(AValue)
  LChess960 = AValue
end

-- =====================================================================

function GetBookMoves(ABook, AMoveSequence)
  local LBranch = ABook
  local LResult = {}
  
  if #AMoveSequence > 0 then
    for i = 1, #AMoveSequence do
      if LBranch[AMoveSequence[i]] == nil then
        return LResult
      else
        LBranch = LBranch[AMoveSequence[i]]
      end
    end
  end
  
  for k, v in pairs(LBranch) do
    table.insert(LResult, k)
  end
  
  return LResult
end

local LBookWhite = require('book/white')
local LBookBlack = require('book/black')
local LMoveSequence = {}

-- =====================================================================

local LValue, LIndex = '', 0

math.randomseed(os.time())


