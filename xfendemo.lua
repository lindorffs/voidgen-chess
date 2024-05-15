
local Chess = require('chess')
local XFEN = require('xfen')

function Test(AFen)
  local LPos = Chess.EncodePosition(AFen)
  local LCastling = LPos.castlingAvailability
  print("-- " .. AFen)
  print("rook file white k. side:", LCastling.K)
  print("          white q. side:", LCastling.Q)
  print("          black k. side:", LCastling.k)
  print("          black q. side:", LCastling.q)
  print("king file              :", LCastling.X)
  print("X-FEN                  :", XFEN.DecodeCastling(LCastling, LPos.piecePlacement, false))
  print("S-FEN                  :", XFEN.DecodeCastling(LCastling, LPos.piecePlacement, true)) -- Shredder-FEN
end

local LSample = {
    "rknbbqnr/pppppppp/8/8/8/8/PPPPPPPP/RKNBBQNR w HAha - 0 1",
    "nrbkqbnr/pppppppp/8/8/8/8/PPPPPPPP/NRBKQBNR w KQkq - 0 1",
    "qrbknbrn/pppppppp/8/8/8/8/PPPPPPPP/QRBKNBRN w GBgb - 0 1",
    "nrbkqrnb/pppppppp/8/8/8/8/PPPPPPPP/NRBKQRNB w FBfb - 0 1",
    "qnrbbknr/pppppppp/8/8/8/8/PPPPPPPP/QNRBBKNR w HChc - 0 1",
    "rnb1k1nr/p1pp1ppp/4p3/1p6/1P6/P1N1PN2/2P2P1P/R1BQKB1q b Qkq - 1 10",
    "rnb1k2r/pppp1pp1/4p2p/8/8/2bPPN2/P2B1PqP/R2QKR2 b Qkq - 1 13",
    "rn2k1r1/ppp1pp1p/3p2p1/5bn1/P7/2N2B2/1PPPPP2/2BNK1RR w Gkq - 4 11",
    'rnb2k1r/pp1Pbppp/2p5/q7/2B5/8/PPPQNnPP/RNB1K2R w KQ - 3 9'
  }

for i = 1, #LSample do
  Test(LSample[i])
end
