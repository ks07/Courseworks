module Calc where
import Data.Char

stringToTokens :: String -> [String]
stringToTokens expr = words expr

isOperator :: String -> Bool
isOperator str = str == "+"

getOperatorArgs :: String -> Int
getOperatorArgs "+" = 2
getOperatorArgs op = error "Unrecognised operator."

doOperation :: String -> [String] -> Double
doOperation "+" args = (read (head args) :: Double) + (read (last args) :: Double)

-- input tokens -> stack -> result
calcPostfix :: [String] -> [String] -> Double
calcPostfix [] stack =
  if (length stack) == 1 then
    read (head stack) :: Double
  else
    error "Multiple values remain in stack."
calcPostfix (next : input) stack =
  if all isDigit next then
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
          
    
    