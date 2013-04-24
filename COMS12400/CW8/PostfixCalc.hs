module Calc where
import Data.Char

stringToTokens :: String -> [String]
stringToTokens expr = words expr

isOperator :: String -> Bool
isOperator "+" = True
isOperator "-" = True
isOperator "*" = True
isOperator "/" = True
isOperator other = False

isNumeric :: String -> Bool
isNumeric [] = False
isNumeric tkn = isNumeric2 tkn False
  where
    isNumeric2 :: String -> Bool -> Bool
    isNumeric2 tkn True = all isDigit tkn 
    isNumeric2 (c : tkn) False = (c == '.' || isDigit c) && isNumeric2 tkn (c == '.')
    isNumeric2 [] dp = True

getOperatorArgs :: String -> Int
getOperatorArgs "+" = 2
getOperatorArgs "-" = 2
getOperatorArgs "*" = 2
getOperatorArgs "/" = 2
getOperatorArgs op = error "Unrecognised operator."

toNum :: String -> Double
toNum num = read num :: Double

doOperation :: String -> [String] -> Double
doOperation "+" (arg1 : arg0 : args) = toNum arg0 + toNum arg1
doOperation "-" (arg1 : arg0 : args) = toNum arg0 - toNum arg1
doOperation "*" (arg1 : arg0 : args) = toNum arg0 * toNum arg1
doOperation "/" (arg1 : arg0 : args) = toNum arg0 / toNum arg1

-- input tokens -> stack -> result
calcPostfix :: [String] -> [String] -> Double
calcPostfix [] stack =
  if (length stack) == 1 then
    read (head stack) :: Double
  else
    error "Multiple values remain in stack."
calcPostfix (next : input) stack =
  if isNumeric next then
    -- push onto stack
    calcPostfix input (next : stack) 
  else
    if isOperator next then
      if (length stack) < (getOperatorArgs next) then
        error "Not enough values for operation."
      else
        calcPostfix input (show (doOperation next (take (getOperatorArgs next) stack)) :  (drop (getOperatorArgs next) stack))
    else
      error "Unexpected string in tokens."
          
    
    